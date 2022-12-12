create procedure ext_tz_names.assert_acceptable_timezone_interval(i in interval)
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  min_utc_offset constant interval not null := (
    select least(
        (select min(utc_offset) from pg_timezone_names),
        (select min(utc_offset) from pg_timezone_abbrevs)
      )
    );

  max_utc_offset constant interval not null := (
    select greatest(
        (select max(utc_offset) from pg_timezone_names),
        (select max(utc_offset) from pg_timezone_abbrevs)
      )
    );

  -- Check that the values are "pure seconds" intervals.
  min_i constant interval_seconds_t not null := min_utc_offset;
  max_i constant interval_seconds_t not null := max_utc_offset;

  -- The interval value must not have a seconds component.
  bad constant boolean not null :=
    not(
        (i between min_i and max_i) and
        (extract(seconds from i) = 0.0)
      );
begin
  if bad then
    declare
      code  constant text not null := '22023';
      msg   constant text not null := 'Invalid value for interval: "'||i::text||'"';
      hint  constant text not null := 'Use a value between "'||min_i||'" and "'||max_i||'" with seconds cpt = zero';
    begin
      raise exception using
        errcode = code,
        message = msg,
        hint    = hint;
    end;
  end if;
end;
$body$;

revoke all     on procedure ext_tz_names.assert_acceptable_timezone_interval(interval) from public;
grant  execute on procedure ext_tz_names.assert_acceptable_timezone_interval(interval) to   public;
