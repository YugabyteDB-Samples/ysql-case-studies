create view ext_tz_names.extended_timezone_names as
select
  name,
  p.abbrev,
  t.std_abbrev,
  t.dst_abbrev,
  p.utc_offset,
  t.std_offset,
  t.dst_offset,
  p.is_dst,
  t.country_code,
  t.lat_long,
  t.region_coverage,
  t.status
from
  pg_timezone_names as p
  inner join
  ext_tz_names.tz_database_time_zones_extended as t using (name);

revoke all    on table ext_tz_names.extended_timezone_names from public;
grant  select on table ext_tz_names.extended_timezone_names to   public;
