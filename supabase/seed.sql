-- Local development seed data. Loaded by `supabase db reset`.
-- Test users sign in with phone OTP; codes are fixed in config.toml
-- ([auth.sms.test_otp]) so no SMS provider is needed locally.
--
--   Admin       +962790000900
--   Drivers     +962790000101, +962790000102, +962790000103
--   Households  +962790000001 (Tla' Al-Ali, high), +962790000002 (Khalda, low),
--               +962790000003 (Marka, middle),
--               +962790000006 / 07 / 08 (Khalda: low / middle / high)
--   OTP for all: 123456

-- ---------------------------------------------------------------------------
-- Locations
-- ---------------------------------------------------------------------------
insert into public.governorates (id, name_ar, name_en) values
  ('10000000-0000-0000-0000-000000000001', 'عمّان', 'Amman');

insert into public.areas (id, governorate_id, name_ar, name_en) values
  ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001',
   'تلاع العلي وأم السماق وخلدا', 'Tla'' Al-Ali, Um Al-Summaq & Khalda'),
  ('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001',
   'ماركا', 'Marka');

insert into public.neighborhoods (id, area_id, name_ar, name_en, center_lat, center_lng) values
  ('30000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001',
   'تلاع العلي', 'Tla'' Al-Ali', 32.0006, 35.8580),
  ('30000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000001',
   'خلدا', 'Khalda', 31.9989, 35.8342),
  ('30000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000002',
   'ماركا', 'Marka', 31.9853, 35.9786);

-- Sample altitude thresholds (meters) used to suggest a home's elevation band
-- from GPS. Placeholder values: replace with real ones from the admin dashboard.
update public.neighborhoods set elevation_low_max_m = 930, elevation_high_min_m = 990
  where id = '30000000-0000-0000-0000-000000000001';
update public.neighborhoods set elevation_low_max_m = 960, elevation_high_min_m = 1020
  where id = '30000000-0000-0000-0000-000000000002';
update public.neighborhoods set elevation_low_max_m = 760, elevation_high_min_m = 820
  where id = '30000000-0000-0000-0000-000000000003';

-- Weekly schedules (ISO weekday: 1 = Monday ... 6 = Saturday, 7 = Sunday).
insert into public.water_schedules (neighborhood_id, weekday, start_time, duration_hours, notes) values
  ('30000000-0000-0000-0000-000000000001', 7, '06:00', 36, 'Sunday morning through Monday evening'),
  ('30000000-0000-0000-0000-000000000002', 2, '08:00', 48, 'Tuesday to Thursday morning'),
  ('30000000-0000-0000-0000-000000000003', 6, '18:00', 24, 'Saturday evening'),
  ('30000000-0000-0000-0000-000000000003', 3, '18:00', 24, 'Wednesday evening');

-- ---------------------------------------------------------------------------
-- Test users
-- ---------------------------------------------------------------------------
create or replace function pg_temp.seed_user(p_id uuid, p_phone text)
returns void
language sql
as $$
  insert into auth.users (
    instance_id, id, aud, role, phone, phone_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, phone_change, phone_change_token, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', p_id, 'authenticated', 'authenticated',
    p_phone, now(),
    '{"provider":"phone","providers":["phone"]}', '{}', now(), now(),
    '', '', '', '', '', '', '', ''
  );
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at, last_sign_in_at)
  values (
    gen_random_uuid(), p_id, p_id::text, 'phone',
    jsonb_build_object('sub', p_id::text, 'phone', p_phone, 'phone_verified', true),
    now(), now(), now()
  );
$$;

select pg_temp.seed_user('40000000-0000-0000-0000-000000000900', '962790000900');
select pg_temp.seed_user('40000000-0000-0000-0000-000000000101', '962790000101');
select pg_temp.seed_user('40000000-0000-0000-0000-000000000102', '962790000102');
select pg_temp.seed_user('40000000-0000-0000-0000-000000000103', '962790000103');
select pg_temp.seed_user('40000000-0000-0000-0000-000000000001', '962790000001');
select pg_temp.seed_user('40000000-0000-0000-0000-000000000002', '962790000002');
select pg_temp.seed_user('40000000-0000-0000-0000-000000000003', '962790000003');
select pg_temp.seed_user('40000000-0000-0000-0000-000000000006', '962790000006');
select pg_temp.seed_user('40000000-0000-0000-0000-000000000007', '962790000007');
select pg_temp.seed_user('40000000-0000-0000-0000-000000000008', '962790000008');

-- Profiles are created by the on_auth_user_created trigger; fill in details.
update public.profiles set role = 'admin', full_name = 'Dor Admin', locale = 'en'
  where id = '40000000-0000-0000-0000-000000000900';

update public.profiles set role = 'driver', full_name = v.name
  from (values
    ('40000000-0000-0000-0000-000000000101'::uuid, 'أبو محمد - صهاريج الشمال'),
    ('40000000-0000-0000-0000-000000000102'::uuid, 'خالد العمري'),
    ('40000000-0000-0000-0000-000000000103'::uuid, 'Sami Haddad')
  ) as v(id, name)
  where profiles.id = v.id;

update public.profiles
   set full_name = v.name, neighborhood_id = v.neighborhood_id, elevation_band = v.band::public.elevation_band
  from (values
    ('40000000-0000-0000-0000-000000000001'::uuid, 'ليلى', '30000000-0000-0000-0000-000000000001'::uuid, 'high'),
    ('40000000-0000-0000-0000-000000000002'::uuid, 'Omar', '30000000-0000-0000-0000-000000000002'::uuid, 'low'),
    ('40000000-0000-0000-0000-000000000003'::uuid, 'رنا', '30000000-0000-0000-0000-000000000003'::uuid, 'middle'),
    ('40000000-0000-0000-0000-000000000006'::uuid, 'سعيد', '30000000-0000-0000-0000-000000000002'::uuid, 'low'),
    ('40000000-0000-0000-0000-000000000007'::uuid, 'Huda', '30000000-0000-0000-0000-000000000002'::uuid, 'middle'),
    ('40000000-0000-0000-0000-000000000008'::uuid, 'ياسر', '30000000-0000-0000-0000-000000000002'::uuid, 'high')
  ) as v(id, name, neighborhood_id, band)
  where profiles.id = v.id;

-- ---------------------------------------------------------------------------
-- Local wiring for the send-notifications job (see 20260927000008). The
-- database reaches the API gateway on the Docker network. Must match
-- NOTIFY_CRON_SECRET in supabase/functions/.env.
-- ---------------------------------------------------------------------------
select vault.create_secret('http://supabase_kong_dor:8000', 'project_url');
select vault.create_secret('local-notify-cron-secret', 'notify_cron_secret');
