set client_min_messages = 'warning';

-- Drop the temporary objects used to populate the "tz_database_time_zones_extended" table.
drop table    if exists  ext_tz_names.tz_database_time_zones_stage            cascade;
drop view     if exists  ext_tz_names.tz_database_time_zones_view             cascade;
drop view     if exists  ext_tz_names.tz_database_time_zones_extended_raw     cascade;
drop table    if exists  ext_tz_names.bad_names                               cascade;
drop function if exists  ext_tz_names.tz_database_time_zones_extended_good()  cascade;
drop function if exists  ext_tz_names.timezones_md_table()                    cascade;
