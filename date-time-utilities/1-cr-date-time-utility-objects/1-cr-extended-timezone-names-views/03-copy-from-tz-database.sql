/*
https://en.wikipedia.org/wiki/List_of_tz_database_time_zones

Country code
Latitude, longitude ±DDMM(SS)±DDDMM(SS)
TZ database name
Portion of country covered
Status
UTC offset ±hh:mm
UTC DST offset ±hh:mm
Notes
*/;
--------------------------------------------------------------------------------

create table ext_tz_names.tz_database_time_zones_stage(
  k                serial not null,
  country_code     text,
  lat_long         text,
  name             text primary key,
  region_coverage  text,
  status           text not null,
  std_offset       text,
  dst_offset       text,
  notes            text
  );

/*
  Define the symbolic link "/etc/ysql-case-studies" to denote the full path for the top directory
  "ysql-case-studies" wherever you place the locally cloned repo on your machine.

  Alternatively, simply place the "ysql-case-studies" to keep path spellings relatively short
  and replace the leading "/etc/" used here with whatever you choose.

  WHY?

  The "\copy" meta-command has no syntax ("like "\copyr" is to "\copy" as "\ir" is to "\i") to
  express that a relative path is to be treated as relative to the directory where the script
  in which it is invoked is found. Rather, it's taken as relative to the current working directory
  from which "psql" or "ysqlsh" is invoked. Nor does "\copy" understand an environment variable.

  If you want to be able to use scripts like this one when "psql" or "ysqlsh" is invoked from
  two or more different directories, you therefore have to use an absolute path. Because this might
  be quite long, you can use a symbolic link (which "\copy" does understand).
*/;

-- The DELIMITER default is a <tab> character in 'TEXT' format and this is what the input file uses.
\copy ext_tz_names.tz_database_time_zones_stage(country_code, lat_long, name, region_coverage, status, std_offset, dst_offset, notes) from /etc/ysql-case-studies/date-time-utilities/1-cr-date-time-utility-objects/1-cr-extended-timezone-names-views/tz-database-timezone-names.data with (format 'text');

-- HEADER option allows TRUE only for 'CSV' format.
-- But the first row in the input file is a header row.
-- So delete this first row (i.e. with "k = 1") immediately after ingest.
delete from ext_tz_names.tz_database_time_zones_stage where k = 1;
