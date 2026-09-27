-- Suggest a neighborhood from the device's location during onboarding.
-- The coordinates are only used for this lookup and are never stored.
--
-- Neighborhoods are represented by a center point for now, so this returns the
-- closest active center within p_max_distance_m (great-circle distance). The
-- user always confirms the suggestion. Swap for polygon containment (PostGIS)
-- once neighborhood boundaries are available.

create or replace function public.nearest_neighborhood(
  p_lat            double precision,
  p_lng            double precision,
  p_max_distance_m double precision default 5000
)
returns table (neighborhood_id uuid, distance_m double precision)
language sql
stable
security invoker   -- RLS applies: only neighborhoods the caller can see
set search_path = ''
as $$
  select n.id, d.distance_m
    from public.neighborhoods n
    cross join lateral (
      select 2 * 6371000 * asin(sqrt(
               power(sin(radians(p_lat - n.center_lat) / 2), 2)
             + cos(radians(n.center_lat)) * cos(radians(p_lat))
             * power(sin(radians(p_lng - n.center_lng) / 2), 2)
             )) as distance_m
    ) d
   where n.is_active
     and n.center_lat is not null
     and n.center_lng is not null
     and p_lat between -90 and 90
     and p_lng between -180 and 180
     and d.distance_m <= least(p_max_distance_m, 20000)
   order by d.distance_m
   limit 1;
$$;

revoke execute on function public.nearest_neighborhood(double precision, double precision, double precision)
  from public, anon;
grant execute on function public.nearest_neighborhood(double precision, double precision, double precision)
  to authenticated;
