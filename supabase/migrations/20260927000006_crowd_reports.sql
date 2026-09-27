-- Crowd reports ("water arrived" / "no water") and live per-band status.
--
-- Rules:
--   * one report per user per neighborhood every rate_limit_hours (6)
--   * status uses each user's latest report in the last window_hours (12)
--   * gravity: an "arrived" report from a higher home implies water at lower
--     homes; a "no water" report from a lower home implies none higher up
--   * reporters who chose "not sure" count as 'middle'

-- ---------------------------------------------------------------------------
-- Tunable settings (admin-editable)
-- ---------------------------------------------------------------------------
create table public.app_settings (
  key        text primary key,
  value      jsonb not null,
  updated_at timestamptz not null default now()
);
create trigger app_settings_set_updated_at
  before update on public.app_settings
  for each row execute function public.set_updated_at();

insert into public.app_settings (key, value) values
  ('crowd_reports', '{"min_reports": 3, "window_hours": 12, "rate_limit_hours": 6}');

create or replace function public.crowd_setting(p_field text, p_default integer)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (select (value ->> p_field)::integer from public.app_settings where key = 'crowd_reports'),
    p_default
  );
$$;

-- ---------------------------------------------------------------------------
-- Reports
-- ---------------------------------------------------------------------------
create type public.report_kind as enum ('arrived', 'no_water');
create type public.report_review as enum ('pending', 'approved', 'rejected');

create table public.crowd_reports (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references public.profiles (id) on delete cascade,
  neighborhood_id uuid not null references public.neighborhoods (id) on delete cascade,
  kind            public.report_kind not null,
  -- Reporter's band when reporting (null = not sure).
  elevation_band  public.elevation_band,
  created_at      timestamptz not null default now(),
  is_flagged      boolean not null default false,
  flag_reasons    text[] not null default '{}',
  -- Only set for flagged reports; 'rejected' reports are ignored by status.
  review_status   public.report_review,
  reviewed_by     uuid references public.profiles (id) on delete set null,
  reviewed_at     timestamptz,
  check (is_flagged = (cardinality(flag_reasons) > 0))
);
create index crowd_reports_neighborhood_created_idx on public.crowd_reports (neighborhood_id, created_at desc);
create index crowd_reports_user_created_idx on public.crowd_reports (user_id, created_at desc);
create index crowd_reports_flagged_idx on public.crowd_reports (created_at desc) where is_flagged;

-- ---------------------------------------------------------------------------
-- Live status, one row per (neighborhood, band). Realtime-enabled.
-- ---------------------------------------------------------------------------
create type public.water_status as enum ('flowing', 'no_water', 'unknown');

create table public.neighborhood_status (
  neighborhood_id       uuid not null references public.neighborhoods (id) on delete cascade,
  elevation_band        public.elevation_band not null,
  status                public.water_status not null default 'unknown',
  flowing_since         timestamptz,
  arrived_count         integer not null default 0,
  no_water_count        integer not null default 0,
  last_report_at        timestamptz,
  updated_at            timestamptz not null default now(),
  -- Notification bookkeeping (prevents repeat alerts when status flaps).
  arrival_notified_at   timestamptz,
  lower_notice_at       timestamptz,
  primary key (neighborhood_id, elevation_band)
);

-- ---------------------------------------------------------------------------
-- Notification outbox, drained by the send-notifications Edge Function.
-- ---------------------------------------------------------------------------
create table public.notification_outbox (
  id              bigint generated always as identity primary key,
  kind            text not null check (kind in ('water_arrived', 'water_reached_lower', 'schedule_reminder')),
  neighborhood_id uuid not null references public.neighborhoods (id) on delete cascade,
  elevation_band  public.elevation_band,
  payload         jsonb not null default '{}',
  created_at      timestamptz not null default now(),
  claimed_at      timestamptz,
  attempts        integer not null default 0,
  processed_at    timestamptz,
  sent_count      integer,
  last_error      text
);
create index notification_outbox_pending_idx on public.notification_outbox (id) where processed_at is null;
-- One day-before reminder per neighborhood per water day.
create unique index notification_outbox_reminder_once_idx
  on public.notification_outbox (neighborhood_id, (payload ->> 'date'))
  where kind = 'schedule_reminder';

-- ---------------------------------------------------------------------------
-- Status computation
-- ---------------------------------------------------------------------------
create or replace function public.refresh_neighborhood_status(p_neighborhood_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_window      interval := make_interval(hours => public.crowd_setting('window_hours', 12));
  v_min         integer  := public.crowd_setting('min_reports', 3);
  v_old_flowing public.elevation_band[];
  v_new_flowing public.elevation_band[];
  v_band        public.elevation_band;
  v_names       jsonb;
begin
  -- Serialize refreshes of the same neighborhood.
  perform pg_advisory_xact_lock(hashtext('neighborhood_status:' || p_neighborhood_id::text));

  select coalesce(array_agg(elevation_band) filter (where status = 'flowing'), '{}')
    into v_old_flowing
    from public.neighborhood_status
   where neighborhood_id = p_neighborhood_id;

  insert into public.neighborhood_status as ns (
    neighborhood_id, elevation_band, status, flowing_since,
    arrived_count, no_water_count, last_report_at, updated_at
  )
  select p_neighborhood_id, e.band,
         case
           when e.arrived >= v_min and e.arrived > e.no_water then 'flowing'
           when e.no_water >= v_min and e.no_water > e.arrived then 'no_water'
           else 'unknown'
         end::public.water_status,
         case when e.arrived >= v_min and e.arrived > e.no_water then e.first_arrived end,
         e.arrived, e.no_water, e.last_report, now()
    from (
      select b.band,
             count(r.*) filter (where r.kind = 'arrived'  and r.band >= b.band)::integer as arrived,
             count(r.*) filter (where r.kind = 'no_water' and r.band <= b.band)::integer as no_water,
             min(r.created_at) filter (where r.kind = 'arrived' and r.band >= b.band) as first_arrived,
             max(r.created_at) as last_report
        from unnest(enum_range(null::public.elevation_band)) as b(band)
        left join (
          -- Each user's latest non-rejected report in the window.
          select distinct on (cr.user_id)
                 cr.kind, coalesce(cr.elevation_band, 'middle') as band, cr.created_at
            from public.crowd_reports cr
           where cr.neighborhood_id = p_neighborhood_id
             and cr.created_at > now() - v_window
             and cr.review_status is distinct from 'rejected'
           order by cr.user_id, cr.created_at desc
        ) r on true
       group by b.band
    ) e
  on conflict (neighborhood_id, elevation_band) do update
     set status         = excluded.status,
         flowing_since  = excluded.flowing_since,
         arrived_count  = excluded.arrived_count,
         no_water_count = excluded.no_water_count,
         last_report_at = excluded.last_report_at,
         updated_at     = excluded.updated_at
   where (ns.status, ns.flowing_since, ns.arrived_count, ns.no_water_count, ns.last_report_at)
         is distinct from
         (excluded.status, excluded.flowing_since, excluded.arrived_count, excluded.no_water_count, excluded.last_report_at);

  select coalesce(array_agg(elevation_band) filter (where status = 'flowing'), '{}')
    into v_new_flowing
    from public.neighborhood_status
   where neighborhood_id = p_neighborhood_id;

  if v_new_flowing <@ v_old_flowing then
    return;  -- nothing started flowing
  end if;

  select jsonb_build_object('name_ar', n.name_ar, 'name_en', n.name_en)
    into v_names
    from public.neighborhoods n
   where n.id = p_neighborhood_id;

  -- "Water arrived" for each band that just started flowing (at most once per window).
  for v_band in
    select ns.elevation_band
      from public.neighborhood_status ns
     where ns.neighborhood_id = p_neighborhood_id
       and ns.elevation_band = any (v_new_flowing)
       and not ns.elevation_band = any (v_old_flowing)
       and (ns.arrival_notified_at is null or ns.arrival_notified_at < now() - v_window)
  loop
    insert into public.notification_outbox (kind, neighborhood_id, elevation_band, payload)
    select 'water_arrived', p_neighborhood_id, v_band,
           v_names || jsonb_build_object('flowing_since', ns.flowing_since, 'confirmations', ns.arrived_count)
      from public.neighborhood_status ns
     where ns.neighborhood_id = p_neighborhood_id and ns.elevation_band = v_band;

    update public.neighborhood_status
       set arrival_notified_at = now()
     where neighborhood_id = p_neighborhood_id and elevation_band = v_band;
  end loop;

  -- Heads-up to higher homes that are still dry while lower homes have water.
  for v_band in
    select ns.elevation_band
      from public.neighborhood_status ns
     where ns.neighborhood_id = p_neighborhood_id
       and not ns.elevation_band = any (v_new_flowing)
       and exists (select 1 from unnest(v_new_flowing) f(band) where f.band < ns.elevation_band)
       and (ns.lower_notice_at is null or ns.lower_notice_at < now() - v_window)
  loop
    insert into public.notification_outbox (kind, neighborhood_id, elevation_band, payload)
    values ('water_reached_lower', p_neighborhood_id, v_band, v_names);

    update public.neighborhood_status
       set lower_notice_at = now()
     where neighborhood_id = p_neighborhood_id and elevation_band = v_band;
  end loop;
end;
$$;

-- Recompute every neighborhood with recent activity so reports age out of the window.
create or replace function public.refresh_active_neighborhood_statuses()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id    uuid;
  v_count integer := 0;
begin
  for v_id in
    select distinct neighborhood_id
      from public.neighborhood_status
     where status <> 'unknown' or arrived_count > 0 or no_water_count > 0
  loop
    perform public.refresh_neighborhood_status(v_id);
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;

create or replace function public.crowd_reports_after_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.refresh_neighborhood_status(new.neighborhood_id);
  return null;
end;
$$;

create trigger crowd_reports_refresh_status
  after insert or update of review_status on public.crowd_reports
  for each row execute function public.crowd_reports_after_change();

-- ---------------------------------------------------------------------------
-- Submitting a report (the only way users create reports)
-- ---------------------------------------------------------------------------
create or replace function public.submit_crowd_report(
  p_neighborhood_id uuid,
  p_kind            public.report_kind
)
returns public.crowd_reports
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user     uuid := auth.uid();
  v_profile  public.profiles;
  v_limit    interval := make_interval(hours => public.crowd_setting('rate_limit_hours', 6));
  v_last     timestamptz;
  v_band     public.elevation_band;
  v_reasons  text[] := '{}';
  v_status   public.neighborhood_status;
  v_opposite integer;
  v_total    integer;
  v_report   public.crowd_reports;
begin
  if v_user is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;
  if not exists (select 1 from public.neighborhoods where id = p_neighborhood_id and is_active) then
    raise exception 'unknown neighborhood' using errcode = '22023';
  end if;

  -- Serialize this user's reports for this neighborhood (double taps, races).
  perform pg_advisory_xact_lock(hashtext('crowd_report:' || v_user::text || ':' || p_neighborhood_id::text));

  select max(created_at) into v_last
    from public.crowd_reports
   where user_id = v_user and neighborhood_id = p_neighborhood_id
     and created_at > now() - v_limit;
  if v_last is not null then
    raise exception 'rate_limited'
      using errcode = 'P0001',
            hint = to_char((v_last + v_limit) at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"');
  end if;

  select * into v_profile from public.profiles where id = v_user;
  v_band := v_profile.elevation_band;

  -- Flag for admin review (flagged reports still count unless rejected).
  if v_profile.neighborhood_id is distinct from p_neighborhood_id then
    v_reasons := array_append(v_reasons, 'not_home_neighborhood');
  end if;
  if v_profile.created_at > now() - interval '1 hour' then
    v_reasons := array_append(v_reasons, 'new_account');
  end if;
  if (select count(distinct neighborhood_id) from public.crowd_reports
       where user_id = v_user and created_at > now() - interval '24 hours'
         and neighborhood_id <> p_neighborhood_id) >= 3 then
    v_reasons := array_append(v_reasons, 'many_neighborhoods');
  end if;
  -- Contradicts a strong majority at the same elevation (different elevations
  -- legitimately disagree, e.g. hilltops still dry while low areas have water).
  select * into v_status from public.neighborhood_status
   where neighborhood_id = p_neighborhood_id and elevation_band = coalesce(v_band, 'middle');
  if found then
    v_total := v_status.arrived_count + v_status.no_water_count;
    v_opposite := case p_kind when 'arrived' then v_status.no_water_count else v_status.arrived_count end;
    if v_opposite >= 10 and v_opposite >= 0.8 * v_total then
      v_reasons := array_append(v_reasons, 'contradicts_majority');
    end if;
  end if;

  insert into public.crowd_reports (
    user_id, neighborhood_id, kind, elevation_band, is_flagged, flag_reasons, review_status
  ) values (
    v_user, p_neighborhood_id, p_kind, v_band, cardinality(v_reasons) > 0, v_reasons,
    case when cardinality(v_reasons) > 0 then 'pending'::public.report_review end
  )
  returning * into v_report;

  return v_report;
end;
$$;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.app_settings        enable row level security;
alter table public.crowd_reports       enable row level security;
alter table public.neighborhood_status enable row level security;
alter table public.notification_outbox enable row level security;

create policy "app_settings: read" on public.app_settings
  for select to authenticated using (true);
create policy "app_settings: admin write" on public.app_settings
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Users see their own reports; raw reports of others are never exposed.
-- Inserts go through submit_crowd_report().
create policy "crowd_reports: read own" on public.crowd_reports
  for select to authenticated using (user_id = auth.uid());
create policy "crowd_reports: admin read" on public.crowd_reports
  for select to authenticated using (public.is_admin());
create policy "crowd_reports: admin review" on public.crowd_reports
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "neighborhood_status: read" on public.neighborhood_status
  for select to authenticated using (true);

create policy "notification_outbox: admin read" on public.notification_outbox
  for select to authenticated using (public.is_admin());

revoke all on public.app_settings, public.crowd_reports, public.neighborhood_status,
  public.notification_outbox from anon;
-- Status rows only change through refresh_neighborhood_status().
revoke insert, update, delete on public.neighborhood_status from authenticated;

revoke execute on function public.refresh_neighborhood_status(uuid) from public, anon, authenticated;
revoke execute on function public.refresh_active_neighborhood_statuses() from public, anon, authenticated;
revoke execute on function public.submit_crowd_report(uuid, public.report_kind) from public, anon;
grant execute on function public.submit_crowd_report(uuid, public.report_kind) to authenticated;

-- Live updates for the status card.
alter publication supabase_realtime add table public.neighborhood_status;
