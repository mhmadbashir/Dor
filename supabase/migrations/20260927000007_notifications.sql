-- Push notification preferences, device tokens, outbox processing helpers and
-- day-before schedule reminders.

alter table public.profiles
  add column notify_water_arrival     boolean not null default true,
  add column notify_schedule_reminder boolean not null default true;

-- ---------------------------------------------------------------------------
-- Device tokens (FCM). A token belongs to whoever signed in on the device last.
-- ---------------------------------------------------------------------------
create table public.device_tokens (
  token      text primary key check (length(token) between 10 and 4096),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  platform   text not null check (platform in ('android', 'ios', 'web')),
  updated_at timestamptz not null default now()
);
create index device_tokens_user_id_idx on public.device_tokens (user_id);

alter table public.device_tokens enable row level security;
create policy "device_tokens: read own" on public.device_tokens
  for select to authenticated using (user_id = auth.uid());
revoke all on public.device_tokens from anon;
revoke insert, update, delete on public.device_tokens from authenticated;

create or replace function public.register_device_token(p_token text, p_platform text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;
  insert into public.device_tokens (token, user_id, platform)
  values (p_token, auth.uid(), p_platform)
  on conflict (token) do update
     set user_id = excluded.user_id, platform = excluded.platform, updated_at = now();
end;
$$;

create or replace function public.unregister_device_token(p_token text)
returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.device_tokens where token = p_token and user_id = auth.uid();
$$;

revoke execute on function public.register_device_token(text, text) from public, anon;
revoke execute on function public.unregister_device_token(text) from public, anon;
grant execute on function public.register_device_token(text, text) to authenticated;
grant execute on function public.unregister_device_token(text) to authenticated;

-- ---------------------------------------------------------------------------
-- Outbox processing (service role only; used by the Edge Function)
-- ---------------------------------------------------------------------------

-- Claims up to p_limit pending messages. A claim expires after 5 minutes so a
-- crashed run is retried; messages are given up after 5 attempts.
create or replace function public.claim_notifications(p_limit integer default 20)
returns setof public.notification_outbox
language sql
security definer
set search_path = ''
as $$
  update public.notification_outbox o
     set claimed_at = now(), attempts = o.attempts + 1
   where o.id in (
     select id from public.notification_outbox
      where processed_at is null
        and attempts < 5
        and (claimed_at is null or claimed_at < now() - interval '5 minutes')
      order by id
      limit p_limit
      for update skip locked
   )
  returning o.*;
$$;

create or replace function public.complete_notification(p_id bigint, p_sent integer, p_error text default null)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.notification_outbox
     set processed_at = case when p_error is null then now() end,
         sent_count   = p_sent,
         last_error   = p_error,
         claimed_at   = case when p_error is null then claimed_at end
   where id = p_id;
$$;

-- Who should receive an outbox message, with the language to write it in.
create or replace function public.notification_recipients(p_outbox_id bigint)
returns table (token text, platform text, locale text)
language sql
stable
security definer
set search_path = ''
as $$
  select t.token, t.platform, p.locale
    from public.notification_outbox o
    join public.profiles p on p.neighborhood_id = o.neighborhood_id
    join public.device_tokens t on t.user_id = p.id
   where o.id = p_outbox_id
     and case o.kind
           when 'schedule_reminder' then p.notify_schedule_reminder
           else p.notify_water_arrival
                -- Reporters who "don't know" their elevation count as middle.
                and coalesce(p.elevation_band, 'middle') = o.elevation_band
         end
     -- People who just confirmed the water themselves don't need the alert.
     and not (
       o.kind = 'water_arrived'
       and exists (
         select 1 from public.crowd_reports r
          where r.user_id = p.id
            and r.neighborhood_id = o.neighborhood_id
            and r.kind = 'arrived'
            and r.created_at > o.created_at - make_interval(hours => public.crowd_setting('window_hours', 12))
       )
     );
$$;

-- Drops tokens FCM reports as unregistered.
create or replace function public.delete_device_tokens(p_tokens text[])
returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.device_tokens where token = any (p_tokens);
$$;

revoke execute on function public.claim_notifications(integer) from public, anon, authenticated;
revoke execute on function public.complete_notification(bigint, integer, text) from public, anon, authenticated;
revoke execute on function public.notification_recipients(bigint) from public, anon, authenticated;
revoke execute on function public.delete_device_tokens(text[]) from public, anon, authenticated;
grant execute on function public.claim_notifications(integer) to service_role;
grant execute on function public.complete_notification(bigint, integer, text) to service_role;
grant execute on function public.notification_recipients(bigint) to service_role;
grant execute on function public.delete_device_tokens(text[]) to service_role;

-- ---------------------------------------------------------------------------
-- Day-before reminders
-- ---------------------------------------------------------------------------
-- Queues one reminder per neighborhood whose water day starts tomorrow
-- (Amman calendar), using the earliest window that day. Idempotent.
create or replace function public.enqueue_schedule_reminders(p_now timestamptz default now())
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_tomorrow date := (p_now at time zone 'Asia/Amman')::date + 1;
  v_count    integer;
begin
  insert into public.notification_outbox (kind, neighborhood_id, payload)
  select distinct on (s.neighborhood_id)
         'schedule_reminder', s.neighborhood_id,
         jsonb_build_object(
           'date', v_tomorrow,
           'start_time', to_char(s.start_time, 'HH24:MI'),
           'duration_hours', s.duration_hours,
           'name_ar', n.name_ar,
           'name_en', n.name_en
         )
    from public.water_schedules s
    join public.neighborhoods n on n.id = s.neighborhood_id and n.is_active
   where s.weekday = extract(isodow from v_tomorrow)
     and (s.effective_from is null or s.effective_from <= v_tomorrow)
     and (s.effective_to is null or s.effective_to >= v_tomorrow)
   order by s.neighborhood_id, s.start_time
  on conflict do nothing;
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke execute on function public.enqueue_schedule_reminders(timestamptz) from public, anon, authenticated;
