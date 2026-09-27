-- Foundation: enums, shared helpers.
-- All timestamps are stored as timestamptz; water schedules are expressed in
-- Asia/Amman local time (Jordan is fixed UTC+3 since 2022).

create type public.user_role as enum ('household', 'driver', 'admin');

-- Keeps updated_at current on any table that has one.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
