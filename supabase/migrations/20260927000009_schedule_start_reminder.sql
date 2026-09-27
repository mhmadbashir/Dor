-- Water-day reminder at the scheduled start time ("your water day starts now,
-- per the schedule"), in addition to the evening-before reminder. It is
-- based on the schedule only; confirmed arrival still comes from neighbors.

alter table public.profiles
  add column notify_schedule_start boolean not null default true;

alter table public.notification_outbox drop constraint notification_outbox_kind_check;
alter table public.notification_outbox add constraint notification_outbox_kind_check
  check (kind in ('water_arrived', 'water_reached_lower', 'schedule_reminder', 'schedule_start'));

-- One start reminder per neighborhood per scheduled window.
create unique index notification_outbox_schedule_start_once_idx
  on public.notification_outbox (neighborhood_id, (payload ->> 'starts_at'))
  where kind = 'schedule_start';

-- Queues a reminder for every window that started in the last 15 minutes
-- (catches up if a cron run is late). Idempotent.
create or replace function public.enqueue_schedule_starts(p_now timestamptz default now())
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer;
begin
  insert into public.notification_outbox (kind, neighborhood_id, payload)
  select 'schedule_start', w.neighborhood_id,
         jsonb_build_object(
           'starts_at', w.starts_at,
           'start_time', to_char(w.start_time, 'HH24:MI'),
           'duration_hours', w.duration_hours,
           'name_ar', w.name_ar,
           'name_en', w.name_en
         )
    from (
      select s.neighborhood_id, s.start_time, s.duration_hours, n.name_ar, n.name_en,
             -- Start instant of the window on each candidate Amman date.
             ((d.day + s.start_time) at time zone 'Asia/Amman') as starts_at,
             d.day
        from public.water_schedules s
        join public.neighborhoods n on n.id = s.neighborhood_id and n.is_active
        cross join lateral (
          -- Today and yesterday (Amman), in case the window started just before midnight.
          select ((p_now at time zone 'Asia/Amman')::date - k) as day
            from generate_series(0, 1) k
        ) d
       where s.weekday = extract(isodow from d.day)
         and (s.effective_from is null or s.effective_from <= d.day)
         and (s.effective_to is null or s.effective_to >= d.day)
    ) w
   where w.starts_at <= p_now
     and w.starts_at > p_now - interval '15 minutes'
  on conflict do nothing;
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke execute on function public.enqueue_schedule_starts(timestamptz) from public, anon, authenticated;

-- Recipients, now including schedule_start.
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
           when 'schedule_start' then
             p.notify_schedule_start
             -- Neighbors at this home's level already confirmed the water:
             -- they got (or will get) "water arrived"; skip the schedule note.
             and not exists (
               select 1 from public.neighborhood_status ns
                where ns.neighborhood_id = o.neighborhood_id
                  and ns.elevation_band = coalesce(p.elevation_band, 'middle')
                  and ns.status = 'flowing'
             )
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

-- Check every minute for windows that just started.
select cron.schedule('enqueue-schedule-starts', '* * * * *', 'select public.enqueue_schedule_starts()');
