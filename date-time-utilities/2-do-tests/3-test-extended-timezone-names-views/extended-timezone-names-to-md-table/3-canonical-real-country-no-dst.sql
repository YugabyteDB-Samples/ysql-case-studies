drop function if exists date_time_tests.timezones_md_table() cascade;
create function date_time_tests.timezones_md_table()
  returns table(z text)
  set search_path = pg_catalog, date_time_tests, ext_tz_names, pg_temp
  language plpgsql
as $body$
declare
  r constant extended_timezone_names_columns_t not null := extended_timezone_names_columns();
begin
  z :=
                                                     '| '||
    rpad('Name',            r.name_pad)            ||'| '||
    rpad('Abbrev',          r.abbrev_pad)          ||'| '||
    rpad('UTC offset',      r.xxx_offset_pad)      ||'| '||
    rpad('Country code',    r.country_code_pad)    ||'| '||
    rpad('Region coverage', r.region_coverage_pad) ||'| ';          return next;

  z :=
                                                     '| '||
    rpad('----',            r.name_pad)            ||'| '||
    rpad('-----------',     r.abbrev_pad)          ||'| '||
    rpad('----------',      r.xxx_offset_pad)      ||'| '||
    rpad('------------',    r.country_code_pad)    ||'| '||
    rpad('---------------', r.region_coverage_pad) ||'| ';          return next;

  for z in (
    select
                                                                  '| '||
      rpad(name,                         r.name_pad)            ||'| '||
      rpad(abbrev,                       r.abbrev_pad)          ||'| '||
      rpad(to_char_interval(utc_offset), r.xxx_offset_pad)      ||'| '||
      rpad(country_code,                 r.country_code_pad)    ||'| '||
      rpad(region_coverage,              r.region_coverage_pad) ||'| '
    from ext_tz_names.canonical_real_country_no_dst
    order by utc_offset, name)
  loop
                                                                    return next;
  end loop;
end;
$body$;

\t on
select client_safe.rule_off('"canonical_real_country_no_dst" .md file', 'level_3');
select z from date_time_tests.timezones_md_table();
\t off
