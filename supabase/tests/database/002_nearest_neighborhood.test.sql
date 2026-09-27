-- nearest_neighborhood(): location-based neighborhood suggestion.
begin;
create extension if not exists pgtap with schema extensions;
select plan(7);

create or replace function pg_temp.login_as(p_user uuid)
returns void language sql as $$
  select set_config('role', 'authenticated', true),
         set_config('request.jwt.claims',
           json_build_object('sub', p_user, 'role', 'authenticated')::text, true);
$$;

select pg_temp.login_as('40000000-0000-0000-0000-000000000001');

-- A few hundred meters from Khalda's center (31.9989, 35.8342).
select is(
  (select neighborhood_id from public.nearest_neighborhood(31.9975, 35.8370)),
  '30000000-0000-0000-0000-000000000002'::uuid,
  'point in Khalda resolves to Khalda');

select is(
  (select neighborhood_id from public.nearest_neighborhood(31.9870, 35.9750)),
  '30000000-0000-0000-0000-000000000003'::uuid,
  'point in Marka resolves to Marka');

select ok(
  (select distance_m < 500 from public.nearest_neighborhood(31.9975, 35.8370)),
  'distance is reported in meters');

select is_empty(
  $$select * from public.nearest_neighborhood(29.5320, 35.0063)$$,
  'Aqaba is outside coverage');

select is_empty(
  $$select * from public.nearest_neighborhood(31.9975, 35.8370, 100)$$,
  'respects a tighter max distance');

-- Inactive neighborhoods are never suggested to households.
reset role;
update public.neighborhoods set is_active = false where name_en = 'Khalda';
select pg_temp.login_as('40000000-0000-0000-0000-000000000001');
select isnt(
  (select neighborhood_id from public.nearest_neighborhood(31.9975, 35.8370)),
  '30000000-0000-0000-0000-000000000002'::uuid,
  'inactive neighborhood is skipped');
reset role;

set local role anon;
select throws_ok(
  $$select * from public.nearest_neighborhood(31.9975, 35.8370)$$,
  '42501', null, 'anon cannot call it');
reset role;

select * from finish();
rollback;
