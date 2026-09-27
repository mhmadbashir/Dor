-- Phase 1: RLS on locations, schedules and profiles.
begin;
create extension if not exists pgtap with schema extensions;
select plan(16);

-- Helper to impersonate a user the way PostgREST does.
create or replace function pg_temp.login_as(p_user uuid)
returns void language sql as $$
  select set_config('role', 'authenticated', true),
         set_config('request.jwt.claims',
           json_build_object('sub', p_user, 'role', 'authenticated')::text, true);
$$;

-- Fixture users (households from seed.sql).
\set household '''40000000-0000-0000-0000-000000000001'''
\set other     '''40000000-0000-0000-0000-000000000002'''
\set admin     '''40000000-0000-0000-0000-000000000900'''

-- RLS is on for every Phase 1 table.
select ok(bool_and(c.relrowsecurity), 'RLS enabled on all Phase 1 tables')
  from pg_class c join pg_namespace n on n.oid = c.relnamespace
 where n.nspname = 'public'
   and c.relname in ('governorates','areas','neighborhoods','water_schedules','profiles');

-- ---------------------------------------------------------------- anon
set local role anon;
select throws_ok('select * from public.neighborhoods', '42501', null, 'anon cannot read neighborhoods');
select throws_ok('select * from public.profiles', '42501', null, 'anon cannot read profiles');
reset role;

-- ---------------------------------------------------------------- household
select pg_temp.login_as(:household);
select is((select count(*)::int from public.neighborhoods), 3, 'household reads neighborhoods');
select is((select count(*)::int from public.water_schedules), 4, 'household reads schedules');
select is((select count(*)::int from public.profiles), 1, 'household sees only own profile');

select lives_ok(
  $$update public.profiles set neighborhood_id = '30000000-0000-0000-0000-000000000002'
     where id = '40000000-0000-0000-0000-000000000001'$$,
  'household can change own neighborhood');

select throws_ok(
  $$update public.profiles set role = 'admin' where id = '40000000-0000-0000-0000-000000000001'$$,
  '42501', 'role cannot be changed', 'household cannot escalate role');

select throws_ok(
  $$update public.profiles set phone = '962700000000' where id = '40000000-0000-0000-0000-000000000001'$$,
  '42501', 'phone cannot be changed', 'household cannot change phone');

-- Updating someone else's row silently matches nothing under RLS.
update public.profiles set full_name = 'hacked' where id = '40000000-0000-0000-0000-000000000002';
reset role;
select is((select full_name from public.profiles where id = :other), 'Omar',
  'household cannot edit another profile');

select pg_temp.login_as(:household);
select throws_ok(
  $$insert into public.neighborhoods (area_id, name_ar, name_en)
    values ('20000000-0000-0000-0000-000000000001', 'x', 'x')$$,
  '42501', null, 'household cannot create neighborhoods');

select throws_ok(
  $$insert into public.water_schedules (neighborhood_id, weekday, start_time, duration_hours)
    values ('30000000-0000-0000-0000-000000000001', 1, '06:00', 12)$$,
  '42501', null, 'household cannot create schedules');

-- Inactive neighborhoods are hidden from non-admins.
reset role;
update public.neighborhoods set is_active = false where name_en = 'Marka';
select pg_temp.login_as(:household);
select is((select count(*)::int from public.neighborhoods), 2, 'inactive neighborhoods hidden');
reset role;

-- ---------------------------------------------------------------- admin
select count(*)::int as total_profiles from public.profiles \gset
select pg_temp.login_as(:admin);
select is((select count(*)::int from public.neighborhoods), 3, 'admin sees inactive neighborhoods');
select is((select count(*)::int from public.profiles), :total_profiles, 'admin reads all profiles');
select lives_ok(
  $$insert into public.water_schedules (neighborhood_id, weekday, start_time, duration_hours)
    values ('30000000-0000-0000-0000-000000000001', 3, '06:00', 12)$$,
  'admin can create schedules');
reset role;

select * from finish();
rollback;
