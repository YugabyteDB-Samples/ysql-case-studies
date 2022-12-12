create view ext_tz_names.approved_timezone_names as
select
  name,
  std_abbrev,
  dst_abbrev,
  std_offset,
  dst_offset
from ext_tz_names.extended_timezone_names
where
  name = 'UTC'

  or

  (
    lower(status) = 'canonical'                                        and
    country_code is not null                                           and
    country_code <> ''                                                 and
    lat_long is not null                                               and
    lat_long <> ''                                                     and

    name not like '%0%'                                                and
    name not like '%1%'                                                and
    name not like '%2%'                                                and
    name not like '%3%'                                                and
    name not like '%4%'                                                and
    name not like '%5%'                                                and
    name not like '%6%'                                                and
    name not like '%7%'                                                and
    name not like '%8%'                                                and
    name not like '%9%'                                                and

    lower(name) not in (select lower(abbrev) from pg_timezone_names)   and
    lower(name) not in (select lower(abbrev) from pg_timezone_abbrevs)
  );

revoke all    on table ext_tz_names.approved_timezone_names from public;
grant  select on table ext_tz_names.approved_timezone_names to   public;
