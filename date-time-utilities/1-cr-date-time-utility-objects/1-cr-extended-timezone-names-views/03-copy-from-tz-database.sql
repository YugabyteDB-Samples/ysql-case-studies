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
  Define "YSQL_CASE_STUDIES" to denote the full path for the top directory "ysql-case-studies"
  wherever you place the locally cloned repo on your machine.

  This is an ugly but apparently necessary workaround.
  The "\copy" metacommand has no syntax ("like "\copyr" is to "\copy" as "\ir" is to "\i") to
  expresss that the path "imdb-data/imdb.small.txt" is to be treated as relative to the directory
  where the script in which it is invoked is found. Rather, it's taken as relative to the
  current working directory from which "psql" or "ysqlsh" is invoked.

  Nor does the "\copy" metacommand understand an environment variable. 

  So the only way to make the present script work when current working directory from which
  "psql" or "ysqlsh" is invoked is not fixed is to use an absolute path.

  The source file for \"copy" is first copied to "/tmp/" so that the "\copy" command itself
  will be easier too read.

  Fortunately, the "\!" metacomand, because it simply passes its patload to the O/S, IS able to
  an environment variable.
*/;
\! cp $YSQL_CASE_STUDIES/date-time-utilities/1-cr-date-time-utility-objects/1-cr-extended-timezone-names-views/tz-database-timezone-names.data /tmp/tz-database-timezone-names.data

-- The DELIMITER default is a <tab> character in 'TEXT' format and this is what the input file uses.
\copy ext_tz_names.tz_database_time_zones_stage(country_code, lat_long, name, region_coverage, status, std_offset, dst_offset, notes) from /tmp/tz-database-timezone-names.data with (format 'text');

-- HEADER option allows TRUE only for 'CSV' format.
-- But the first row in the input file is a header row.
-- So delete this first row (i.e. with "k = 1") immediately after ingest.
delete from ext_tz_names.tz_database_time_zones_stage where k = 1;
