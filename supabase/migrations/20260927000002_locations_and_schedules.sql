-- Location hierarchy (governorate > area > neighborhood) and weekly water schedules.

create table public.governorates (
  id         uuid primary key default gen_random_uuid(),
  name_ar    text not null check (length(trim(name_ar)) > 0),
  name_en    text not null check (length(trim(name_en)) > 0),
  created_at timestamptz not null default now(),
  unique (name_en)
);

create table public.areas (
  id             uuid primary key default gen_random_uuid(),
  governorate_id uuid not null references public.governorates (id) on delete restrict,
  name_ar        text not null check (length(trim(name_ar)) > 0),
  name_en        text not null check (length(trim(name_en)) > 0),
  created_at     timestamptz not null default now(),
  unique (governorate_id, name_en)
);
create index areas_governorate_id_idx on public.areas (governorate_id);

create table public.neighborhoods (
  id         uuid primary key default gen_random_uuid(),
  area_id    uuid not null references public.areas (id) on delete restrict,
  name_ar    text not null check (length(trim(name_ar)) > 0),
  name_en    text not null check (length(trim(name_en)) > 0),
  center_lat double precision check (center_lat between -90 and 90),
  center_lng double precision check (center_lng between -180 and 180),
  is_active  boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (area_id, name_en)
);
create index neighborhoods_area_id_idx on public.neighborhoods (area_id);
create trigger neighborhoods_set_updated_at
  before update on public.neighborhoods
  for each row execute function public.set_updated_at();

-- One row per weekly supply window. weekday follows ISO 8601 (1 = Monday ... 7 = Sunday),
-- matching Dart's DateTime.weekday. start_time is Asia/Amman local time.
-- Supply often lasts more than a day, so a window is start + duration.
create table public.water_schedules (
  id              uuid primary key default gen_random_uuid(),
  neighborhood_id uuid not null references public.neighborhoods (id) on delete cascade,
  weekday         smallint not null check (weekday between 1 and 7),
  start_time      time not null,
  duration_hours  smallint not null check (duration_hours between 1 and 168),
  effective_from  date,
  effective_to    date,
  notes           text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  check (effective_to is null or effective_from is null or effective_to >= effective_from),
  unique (neighborhood_id, weekday, start_time)
);
create index water_schedules_neighborhood_id_idx on public.water_schedules (neighborhood_id);
create trigger water_schedules_set_updated_at
  before update on public.water_schedules
  for each row execute function public.set_updated_at();
