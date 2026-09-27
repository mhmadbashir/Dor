-- Home elevation within a neighborhood. Water in the rotation reaches
-- low-lying homes first and homes on hills last (or with weak pressure),
-- so live status and alerts are tracked per elevation band.

create type public.elevation_band as enum ('low', 'middle', 'high');  -- order matters: low < middle < high

-- Chosen by the user (optionally suggested from GPS altitude). Null = "not sure".
alter table public.profiles
  add column elevation_band public.elevation_band;

-- Optional altitude thresholds (meters above sea level) the app uses to
-- suggest a band from the device's GPS altitude. Maintained by admins.
alter table public.neighborhoods
  add column elevation_low_max_m  numeric(6, 1),
  add column elevation_high_min_m numeric(6, 1),
  add constraint neighborhoods_elevation_thresholds_check check (
    elevation_low_max_m is null
    or elevation_high_min_m is null
    or elevation_low_max_m < elevation_high_min_m
  );
