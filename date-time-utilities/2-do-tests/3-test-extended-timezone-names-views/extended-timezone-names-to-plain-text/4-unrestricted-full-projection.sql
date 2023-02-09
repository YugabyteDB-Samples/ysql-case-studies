\t on
select client_safe.rule_off('"extended_timezone_names" plain text', 'level_3');

select
  name,
  abbrev,
  std_abbrev,
  dst_abbrev,
  lpad(ext_tz_names.to_char_interval(utc_offset), 6) as "UTC offset",
  lpad(ext_tz_names.to_char_interval(std_offset), 6) as "STD offset",
  lpad(ext_tz_names.to_char_interval(dst_offset), 6) as "DST offset",
  is_dst::text,
  country_code,
  lat_long,
  region_coverage,
  status
from ext_tz_names.extended_timezone_names
order by utc_offset, name;
\t off
