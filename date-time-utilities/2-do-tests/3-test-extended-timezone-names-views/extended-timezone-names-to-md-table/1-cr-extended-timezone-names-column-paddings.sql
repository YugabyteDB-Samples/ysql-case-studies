create type date_time_tests.extended_timezone_names_columns_t as (
  name_pad             int,
  abbrev_pad           int,
  xxx_offset_pad       int,
  is_dst_pad           int,
  country_code_pad     int,
  lat_long_pad         int,
  region_coverage_pad  int,
  status_pad           int);

create function date_time_tests.extended_timezone_names_columns()
  returns extended_timezone_names_columns_t
  set search_path = pg_catalog, date_time_tests, ext_tz_names, pg_temp
  language plpgsql
as $body$
<<b>>declare
  name_pad             constant int not null :=
                         greatest(
                           (select max(length(name)) + 1 from extended_timezone_names),
                           length('name '));

  abbrev_pad           constant int not null :=
                         greatest(
                           (select max(length(abbrev)) + 1 from extended_timezone_names),
                           length('dst_abbrev '));

  xxx_offset_pad       constant int not null :=
                         greatest(
                           (select max(length(to_char_interval(utc_offset))) + 1 from extended_timezone_names),
                           length('utc_offset '));

  is_dst_pad           constant int not null :=
                         greatest(
                           (select max(length(is_dst::text)) + 1 from extended_timezone_names),
                           length('is_dst '));

  country_code_pad     constant int not null :=
                         greatest(
                           (select max(length(country_code)) + 1 from extended_timezone_names),
                           length('country_code '));

  lat_long_pad         constant int not null :=
                         greatest(
                           (select max(length(lat_long)) + 1 from extended_timezone_names),
                           length('lat_long '));

  region_coverage_pad  constant int not null :=
                         greatest(
                           (select max(length(region_coverage)) + 1 from extended_timezone_names),
                           length('region_coverage '));

  status_pad           constant int not null :=
                         greatest(
                           (select max(length(status)) + 1 from extended_timezone_names),
                           length('status '));
  r                    constant extended_timezone_names_columns_t not null := (
                          b.name_pad,
                          b.abbrev_pad,
                          b.xxx_offset_pad,
                          b.is_dst_pad,
                          b.country_code_pad,
                          b.lat_long_pad,
                          b.region_coverage_pad,
                          b.status_pad)::extended_timezone_names_columns_t;
begin
  return r;
end b;
$body$;
