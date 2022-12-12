create view ext_tz_names.canonical_no_country_no_dst as
select name, utc_offset
from ext_tz_names.extended_timezone_names
where
  name = 'UTC'

  or

  (
    -- There are rows with names 'Etc/GMT-0', 'Etc/GMT', and 'Etc/GMT0', all of
    -- which have an offset of zero from UTC. These entries are therefore redundant.
    name like 'Etc/GMT%'           and
    utc_offset <> make_interval()  and

    lower(status) = 'canonical'    and

    std_offset = dst_offset        and

    (
      country_code is null or
      country_code = ''
    )                              and

    (
      lat_long is null or
      lat_long = ''
    )                              and

    (
      region_coverage is null or
      region_coverage = ''
    )                              and

    lower(name) not in (select lower(abbrev) from pg_timezone_names) and
    lower(name) not in (select lower(abbrev) from pg_timezone_abbrevs)
  );

revoke all    on table ext_tz_names.canonical_no_country_no_dst from public;
grant  select on table ext_tz_names.canonical_no_country_no_dst to   public;
