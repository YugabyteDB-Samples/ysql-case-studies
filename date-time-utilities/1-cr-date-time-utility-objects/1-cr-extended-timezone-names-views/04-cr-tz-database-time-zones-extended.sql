/*
Create the "tz_database_time_zones_extended" table.
This is joined with "pg_timezone_names" to define the "extended_timezone_names" view.
The facts change periodically. You must therefore re-run the "extended-timezone-names" kit
on this directory and the companion "set-timezone-and-at-timezone-encapsulations" kit
periodically (at at least whenever the YB version is upgraded.

It uses "jan_and_jul_tz_abbrevs_and_offsets()" to add
"dst_abbrev" and "std_offset" to the downloaded "tz database" data.

Fix up the few cases where "std_offset" and "dst_offset" are
back-to-front in the "tz database" data.

Eliminate any rows where the "tz database" STD and DST offsets
disagree with the "Jan" and "Jul" offsets computed from "pg_timezone"names".
*/;

-- The original data (scraped from the browser view of the page using "Edge" on MSFT Windows 10)
-- uses ascii code 8722 and not the plain "-" (ascii code 45).
-- This causes no end of problems. For example, what looks like '-03:00' cannot be typecast to interval!
-- ERROR:  invalid input syntax for type interval: "−03:00".
create view ext_tz_names.tz_database_time_zones_view as
select
  name,
  replace(t.std_offset, chr(8722), '-')::interval as std_offset, -- LOOK !
  replace(t.dst_offset, chr(8722), '-')::interval as dst_offset, -- LOOK !
  country_code,
  replace(t.lat_long, chr(8722), '-') as lat_long,               -- LOOK !
  region_coverage,
  status
from ext_tz_names.tz_database_time_zones_stage as t;

create view ext_tz_names.tz_database_time_zones_extended_raw as
select
  p.name,
  f.jan_abbrev,
  f.jul_abbrev,
  f.jan_offset,
  f.jul_offset,
  t.std_offset,
  t.dst_offset,
  t.country_code,
  t.lat_long,
  t.region_coverage,
  t.status
from
  pg_timezone_names as p
  inner join
  ext_tz_names.jan_and_jul_tz_abbrevs_and_offsets() as f using (name)
  inner join
  ext_tz_names.tz_database_time_zones_view as t using (name)
-- Eliminates dirty data in YB 2.4.
where p.utc_offset in (t.std_offset, t.dst_offset);

create table ext_tz_names.bad_names(name text primary key);

create function ext_tz_names.tz_database_time_zones_extended_good()
  returns table (
    name             text,
    std_abbrev       text,
    dst_abbrev       text,
    std_offset       interval,
    dst_offset       interval,
    country_code     text,
    lat_long         text,
    region_coverage  text,
    status           text)
  set search_path = pg_catalog, dt_utils, pg_temp
  language plpgsql
as $body$
declare
  jan_offset interval not null := make_interval();
  jul_offset interval not null := make_interval();
begin
  delete from ext_tz_names.bad_names;
  for
    name,
    std_abbrev,
    dst_abbrev,
    jan_offset,
    jul_offset,
    std_offset,
    dst_offset,
    country_code,
    lat_long,
    region_coverage,
    status
  in
    (
      select
        e.name,
        e.jan_abbrev,
        e.jul_abbrev,
        e.jan_offset,
        e.jul_offset,
        e.std_offset,
        e.dst_offset,
        e.country_code,
        e.lat_long,
        e.region_coverage,
        e.status
      from ext_tz_names.tz_database_time_zones_extended_raw as e
    )
  loop
    -- Fix the bug from the "List of tz database time zones" page.
    if std_offset > dst_offset then
      declare
        temp constant interval not null := std_offset;
      begin
        std_offset := dst_offset;
        dst_offset := temp;
      end;
    end if;

    if
      (least   (std_offset, dst_offset) = least   (jan_offset, jul_offset))
      and
      (greatest(std_offset, dst_offset) = greatest(jan_offset, jul_offset))
    then
      case
        -- Northern hemisphere. No action needed.
        -- Explicit test as self-doc. The "case_not_found" error is unexpected.
        when (jan_offset = std_offset) and (jul_offset = dst_offset) then
          null;

        -- Southern hemisphere
        -- Twizzle std_abbrev (from jan_abbrev) and dst_abbrev (from jul_abbrev).
        when (jan_offset = dst_offset) and (jul_offset = std_offset) then
          declare
            temp constant text not null := std_abbrev;
          begin
            std_abbrev := dst_abbrev;
            dst_abbrev := temp;
          end;
        end case;

      return next;
    else
      insert into ext_tz_names.bad_names(name) values(name);
    end if;
  end loop;
end;
$body$;

create table ext_tz_names.tz_database_time_zones_extended(
  name             text primary key,
  std_abbrev       text,
  dst_abbrev       text,
  std_offset       interval,
  dst_offset       interval,
  country_code     text,
  lat_long         text,
  region_coverage  text,
  status           text not null
  );

insert into ext_tz_names.tz_database_time_zones_extended(
  name,
  std_abbrev,
  dst_abbrev,
  std_offset,
  dst_offset,
  country_code,
  lat_long,
  region_coverage,
  status)
select
  name,
  std_abbrev,
  dst_abbrev,
  std_offset,
  dst_offset,
  country_code,
  lat_long,
  region_coverage,
  status
from ext_tz_names.tz_database_time_zones_extended_good()
-- Queries will be typically ordered by name.
order by name;
