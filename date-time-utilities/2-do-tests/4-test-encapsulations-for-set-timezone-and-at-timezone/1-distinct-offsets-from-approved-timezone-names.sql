-- Force the use of qualified idenitifiers
set search_path = pg_catalog, pg_temp;

create view date_time_tests.distinct_offsets as
with v as (
  select distinct std_offset as the_offset from ext_tz_names.approved_timezone_names
  union
  select distinct dst_offset as the_offset from ext_tz_names.approved_timezone_names
  )
select distinct the_offset from v;

do $body$
declare
  n constant int not null := (select count(the_offset) from date_time_tests.distinct_offsets);
begin
  assert n = 39, 'Assert failed';
end;
$body$;

do $body$
begin
  -- Prove that distinct_offsets.the_offset is a "pure seconds" interval .
  declare
    x int not null := (
      with
        v as (select dt_utils.interval_mm_dd_ss(the_offset) as i from date_time_tests.distinct_offsets)
      select
        (select count(*) as "count w/ non-zero mm" from v where (i).mm <> 0::double precision) +
        (select count(*) as "count w/ non-zero dd" from v where (i).dd <> 0::double precision)
      );
  begin
    assert x = 0::double precision, 'assert #1 failed';
  end;

  -- Prove that the ss value of distinct_offsets.the_offset is an integral no. of quarter-hours.
  declare
    x numeric not null := (
      with
        v as (select dt_utils.interval_mm_dd_ss(the_offset) as i from date_time_tests.distinct_offsets)
      select sum(mod((i).ss::numeric, 60*15::numeric)) from v
      );
  begin
    assert x = 0::numeric, 'assert #2 failed';
  end;
end;
$body$;

\t on \\ select client_safe.rule_off('The "approved_timezone_names" view', 'level_2'); \t off

\t on \\ select client_safe.rule_off('distinct offsets from "approved_timezone_names"', 'level_3'); \t off
-- List all distinct values of the_offset
with
  v1 as (select the_offset as i from date_time_tests.distinct_offsets)
select
  extract(hour   from i) as "hour",
  extract(minute from i) as "minute"
from v1
order by 1, 2;

\t on \\ select client_safe.rule_off('timezones where offset isn''t an integral no. of hours', 'level_3'); \t off
with
  v as (
    select the_offset from date_time_tests.distinct_offsets
    where mod((dt_utils.interval_mm_dd_ss(the_offset)).ss::numeric, 60*60::numeric) <> 0::numeric)
select
  name,
  lpad(std_offset::text, 9) as "std offset",
  lpad(dst_offset::text, 9) as "dst offset"
from ext_tz_names.approved_timezone_names
where
  std_offset in (select the_offset from v) or
  dst_offset in (select the_offset from v)
order by std_offset, dst_offset, name;
