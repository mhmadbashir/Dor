-- Phase 2: crowd reports, per-elevation live status, notifications outbox.
-- Note: the whole test runs in one transaction, so now() is constant.
begin;
create extension if not exists pgtap with schema extensions;
select plan(39);

create or replace function pg_temp.login_as(p_user uuid)
returns void language sql as $$
  select set_config('role', 'authenticated', true),
         set_config('request.jwt.claims',
           json_build_object('sub', p_user, 'role', 'authenticated')::text, true);
$$;

create or replace function pg_temp.band(p_band text)
returns public.neighborhood_status language sql as $$
  select * from public.neighborhood_status
   where neighborhood_id = '30000000-0000-0000-0000-000000000002'
     and elevation_band = p_band::public.elevation_band;
$$;

-- Seeded users are brand new; age them so they aren't flagged as new accounts.
update public.profiles set created_at = now() - interval '30 days';

-- Khalda households: 02 low, 06 low, 07 middle, 08 high.
\set khalda '''30000000-0000-0000-0000-000000000002'''
\set marka  '''30000000-0000-0000-0000-000000000003'''
\set tlaa   '''30000000-0000-0000-0000-000000000001'''
\set u02 '''40000000-0000-0000-0000-000000000002'''
\set u06 '''40000000-0000-0000-0000-000000000006'''
\set u07 '''40000000-0000-0000-0000-000000000007'''
\set u08 '''40000000-0000-0000-0000-000000000008'''
\set u01 '''40000000-0000-0000-0000-000000000001'''

-- ============================================================ submitting
select pg_temp.login_as(:u02);
select is(
  (select row(kind, elevation_band, is_flagged)::text
     from public.submit_crowd_report(:khalda, 'arrived')),
  '(arrived,low,f)',
  'report snapshots the reporter''s elevation band and is not flagged');

select throws_ok(
  $$select public.submit_crowd_report('30000000-0000-0000-0000-000000000002', 'no_water')$$,
  'P0001', 'rate_limited', 'second report within 6 hours is rejected');

select ok(
  (select public.submit_crowd_report(:marka, 'arrived')).flag_reasons @> '{not_home_neighborhood}',
  'reporting another neighborhood is allowed but flagged');

select throws_ok(
  $$insert into public.crowd_reports (user_id, neighborhood_id, kind)
    values ('40000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000002', 'arrived')$$,
  '42501', null, 'direct inserts are not allowed');

select is((select count(*)::int from public.crowd_reports), 2, 'users read only their own reports');
reset role;

select is((pg_temp.band('low')).arrived_count, 1, 'one report counted');
select is((pg_temp.band('low')).status, 'unknown'::public.water_status, 'one report is not enough');

-- ============================================================ per-band status
select pg_temp.login_as(:u06);
select lives_ok($$select public.submit_crowd_report('30000000-0000-0000-0000-000000000002', 'arrived')$$, 'u06 reports');
select pg_temp.login_as(:u07);
select lives_ok($$select public.submit_crowd_report('30000000-0000-0000-0000-000000000002', 'arrived')$$, 'u07 reports');
reset role;

select is((pg_temp.band('low')).status, 'flowing'::public.water_status,
  'low homes flowing: 2 low reports + 1 middle report (water reaching the middle implies low)');
select is((pg_temp.band('low')).arrived_count, 3, 'low band counts reports from its level and above');
select is((pg_temp.band('middle')).arrived_count, 1, 'middle band ignores reports from lower homes');
select is((pg_temp.band('middle')).status, 'unknown'::public.water_status, 'middle not confirmed yet');
select is((pg_temp.band('high')).status, 'unknown'::public.water_status, 'high not confirmed yet');
select ok((pg_temp.band('low')).flowing_since is not null, 'flowing_since is set');

select is(
  (select count(*)::int from public.notification_outbox
    where kind = 'water_arrived' and neighborhood_id = :khalda and elevation_band = 'low'),
  1, 'arrival alert queued for low homes');
select is(
  (select array_agg(elevation_band::text order by elevation_band) from public.notification_outbox
    where kind = 'water_reached_lower' and neighborhood_id = :khalda),
  array['middle', 'high'], 'higher homes get a "reached lower areas" heads-up');
select is(
  (select payload ->> 'name_en' from public.notification_outbox where kind = 'water_arrived' limit 1),
  'Khalda', 'payload carries the neighborhood name');

-- A hilltop "no water" says nothing about lower homes.
select pg_temp.login_as(:u08);
select lives_ok($$select public.submit_crowd_report('30000000-0000-0000-0000-000000000002', 'no_water')$$, 'u08 reports');
reset role;
select is((pg_temp.band('high')).no_water_count, 1, 'high band sees the no-water report');
select is((pg_temp.band('low')).no_water_count, 0, 'low band ignores no-water from higher homes');
select is((pg_temp.band('low')).status, 'flowing'::public.water_status, 'low homes still flowing');

-- ============================================================ window & flapping
update public.crowd_reports set created_at = now() - interval '13 hours'
 where neighborhood_id = :khalda;
select public.refresh_active_neighborhood_statuses();
select is((pg_temp.band('low')).status, 'unknown'::public.water_status, 'reports older than 12 hours expire');
select is((pg_temp.band('low')).arrived_count, 0, 'expired reports are not counted');

-- Water flows again within the window: no second alert.
insert into public.crowd_reports (user_id, neighborhood_id, kind, elevation_band)
values (:u02, :khalda, 'arrived', 'low'), (:u06, :khalda, 'arrived', 'low'), (:u07, :khalda, 'arrived', 'middle');
select is((pg_temp.band('low')).status, 'flowing'::public.water_status, 'flowing again');
select is(
  (select count(*)::int from public.notification_outbox where kind = 'water_arrived' and elevation_band = 'low'),
  1, 'no repeat alert when status flaps within 12 hours');

-- Each user's latest report wins.
insert into public.crowd_reports (user_id, neighborhood_id, kind, elevation_band, created_at)
values (:u06, :khalda, 'no_water', 'low', now() + interval '1 second');
select is((pg_temp.band('low')).arrived_count, 2, 'a newer report replaces the user''s earlier one');

-- Rejected reports are ignored.
update public.crowd_reports set review_status = 'rejected'
 where user_id = :u07 and neighborhood_id = :khalda;
select is((pg_temp.band('low')).arrived_count, 1, 'rejected reports do not count');

-- ============================================================ flagging
-- 10 middle-band neighbors in Tla' Al-Ali report no water.
insert into auth.users (id, instance_id, aud, role)
select gen_random_uuid(), '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'
  from generate_series(1, 10);
update public.profiles set neighborhood_id = :tlaa, elevation_band = 'middle'
 where phone is null;
insert into public.crowd_reports (user_id, neighborhood_id, kind, elevation_band)
select id, :tlaa, 'no_water', 'middle' from public.profiles where phone is null;

-- u01 lives on the hill: water not reaching the middle means none higher up either.
select pg_temp.login_as(:u01);
select ok(
  (select public.submit_crowd_report(:tlaa, 'arrived')).flag_reasons @> '{contradicts_majority}',
  'contradicting a strong majority at the same elevation is flagged');
reset role;

select pg_temp.login_as((select id from public.profiles where phone is null limit 1));
select ok(
  (select public.submit_crowd_report(:khalda, 'arrived')).flag_reasons @> '{new_account,not_home_neighborhood}',
  'brand-new accounts are flagged');
reset role;

-- ============================================================ status RLS
select pg_temp.login_as(:u02);
select is((select count(*)::int from public.neighborhood_status where neighborhood_id = :khalda), 3,
  'households read live status');
select throws_ok(
  $$update public.neighborhood_status set status = 'flowing'$$,
  '42501', null, 'households cannot change status');
reset role;

-- ============================================================ recipients & tokens
select pg_temp.login_as(:u02);
select lives_ok($$select public.register_device_token('token-u02-xxxxxxxx', 'android')$$, 'register token');
select throws_ok($$select * from public.claim_notifications(10)$$, '42501', null,
  'users cannot drain the outbox');
reset role;
select pg_temp.login_as(:u08);
select public.register_device_token('token-u08-xxxxxxxx', 'ios');
reset role;

select is(
  (select array_agg(token) from public.notification_recipients(
     (select id from public.notification_outbox where kind = 'water_arrived' and elevation_band = 'low'))),
  null, 'people who confirmed the water themselves are not alerted');
select is(
  (select array_agg(token) from public.notification_recipients(
     (select id from public.notification_outbox where kind = 'water_reached_lower' and elevation_band = 'high'))),
  array['token-u08-xxxxxxxx'], 'hilltop homes get the heads-up');

update public.profiles set notify_water_arrival = false where id = :u08;
select is(
  (select count(*)::int from public.notification_recipients(
     (select id from public.notification_outbox where kind = 'water_reached_lower' and elevation_band = 'high'))),
  0, 'users can turn arrival alerts off');

-- ============================================================ reminders
-- Monday evening in Amman: Khalda's water day (Tuesday) is tomorrow.
select is(public.enqueue_schedule_reminders('2026-09-28 18:00+03'), 1, 'reminder queued for Khalda');
select is(public.enqueue_schedule_reminders('2026-09-28 20:00+03'), 0, 'reminders are queued once');

select * from finish();
rollback;
