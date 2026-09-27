-- User profiles, role helpers and RLS for Phase 1 tables.

create table public.profiles (
  id              uuid primary key references auth.users (id) on delete cascade,
  role            public.user_role not null default 'household',
  full_name       text check (full_name is null or length(full_name) <= 100),
  phone           text,
  neighborhood_id uuid references public.neighborhoods (id) on delete set null,
  locale          text not null default 'ar' check (locale in ('ar', 'en')),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index profiles_neighborhood_id_idx on public.profiles (neighborhood_id);
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Role helpers. SECURITY DEFINER so they can read profiles without recursing
-- through the profiles RLS policies.
-- ---------------------------------------------------------------------------
create or replace function public.current_role_name()
returns public.user_role
language sql
stable
security definer
set search_path = ''
as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (select role = 'admin' from public.profiles where id = auth.uid()),
    false
  );
$$;

create or replace function public.my_neighborhood_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select neighborhood_id from public.profiles where id = auth.uid();
$$;

-- ---------------------------------------------------------------------------
-- Create a profile automatically for every new auth user (phone OTP sign-up).
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, phone)
  values (new.id, new.phone)
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Column guard: end users may edit their name, neighborhood and locale only.
-- Role and phone can be changed by admins or by trusted server contexts
-- (service role / migrations, where auth.uid() is null).
-- ---------------------------------------------------------------------------
create or replace function public.guard_profile_columns()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    if new.role is distinct from old.role then
      raise exception 'role cannot be changed' using errcode = '42501';
    end if;
    if new.phone is distinct from old.phone then
      raise exception 'phone cannot be changed' using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;

create trigger profiles_guard_columns
  before update on public.profiles
  for each row execute function public.guard_profile_columns();

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
alter table public.governorates    enable row level security;
alter table public.areas           enable row level security;
alter table public.neighborhoods   enable row level security;
alter table public.water_schedules enable row level security;
alter table public.profiles        enable row level security;

-- Reference data: readable by any signed-in user, writable by admins only.
create policy "governorates: read" on public.governorates
  for select to authenticated using (true);
create policy "governorates: admin write" on public.governorates
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "areas: read" on public.areas
  for select to authenticated using (true);
create policy "areas: admin write" on public.areas
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "neighborhoods: read active" on public.neighborhoods
  for select to authenticated using (is_active or public.is_admin());
create policy "neighborhoods: admin write" on public.neighborhoods
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "water_schedules: read" on public.water_schedules
  for select to authenticated using (true);
create policy "water_schedules: admin write" on public.water_schedules
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Profiles: users see and edit their own row; admins see and edit all.
-- Inserts happen only through the auth trigger, deletes cascade from auth.users.
create policy "profiles: read own" on public.profiles
  for select to authenticated using (id = auth.uid());
create policy "profiles: admin read" on public.profiles
  for select to authenticated using (public.is_admin());
create policy "profiles: update own" on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy "profiles: admin update" on public.profiles
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- Anonymous users get nothing.
revoke all on public.governorates, public.areas, public.neighborhoods,
  public.water_schedules, public.profiles from anon;
