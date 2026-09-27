-- Water-day reminder at the scheduled start time.
begin;
create extension if not exists pgtap with schema extensions;
select plan(8);

\set khalda '''30000000-0000-0000-0000-000000000002'''
\set u02 '''40000000-0000-0000-0000-000000000002'''
\set u08 '''40000000-0000-0000-0000-000000000008'''

-- Khalda: Tuesday 08:00 Amman (2026-09-29 is a Tuesday).
select is(public.enqueue_schedule_starts('2026-09-29 07:59+03'), 0, 'nothing before the start time');
select is(public.enqueue_schedule_starts('2026-09-29 08:00+03'), 1, 'queued at the start time');
select is(public.enqueue_schedule_starts('2026-09-29 08:05+03'), 0, 'queued only once per window');
select is(
  (select payload ->> 'start_time' from public.notification_outbox where kind = 'schedule_start'),
  '08:00', 'payload carries the local start time');

-- A late cron run still catches up within 15 minutes, but not later.
select is(public.enqueue_schedule_starts('2026-09-27 06:14+03'), 1, 'late run within 15 minutes still sends (Tla'' Al-Ali, Sunday 06:00)');
select is(public.enqueue_schedule_starts('2026-10-04 06:20+03'), 0, 'too late: skipped rather than sent stale');

-- Recipients: everyone in the neighborhood with the reminder on, except homes
-- whose level neighbors already confirmed the water.
insert into public.device_tokens (token, user_id, platform) values
  ('token-u02-xxxxxxxx', :u02, 'android'),
  ('token-u08-xxxxxxxx', :u08, 'ios');
insert into public.neighborhood_status (neighborhood_id, elevation_band, status, flowing_since, arrived_count)
values (:khalda, 'low', 'flowing', now(), 3);

select is(
  (select array_agg(token) from public.notification_recipients(
     (select id from public.notification_outbox where kind = 'schedule_start' and neighborhood_id = :khalda))),
  array['token-u08-xxxxxxxx'], 'skips homes where water is already confirmed at their level');

update public.profiles set notify_schedule_start = false where id = :u08;
select is(
  (select count(*)::int from public.notification_recipients(
     (select id from public.notification_outbox where kind = 'schedule_start' and neighborhood_id = :khalda))),
  0, 'users can turn the start reminder off');

select * from finish();
rollback;
