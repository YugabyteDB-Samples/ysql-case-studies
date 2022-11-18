-- Generic helper. Comparing two nominally equal "double precision" values
-- for exact equality is bound to give FALSE now and then because of rounding errors.
-- Because, here, "double precision" values represent seconds, and the internal
-- representation records these only with microsecond precision, it's good enough
-- to test using a 0.1 microsecond tolerance.
create function dt_utils.approx_equals(v1 in double precision, v2 in double precision) 
  returns boolean
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  microseconds_diff       constant double precision not null := abs(v1 - v2);
  point_one_microseconds  constant double precision not null := 0.0000001;
  eq                      constant boolean          not null := microseconds_diff < point_one_microseconds;
begin
  return eq;
end;
$body$;
revoke all     on function dt_utils.approx_equals(double precision, double precision) from public;
grant  execute on function dt_utils.approx_equals(double precision, double precision) to   public;

-- Notice that an operator is executable by a role "r" if "r" can execute its implementation function.
create operator dt_utils.~= (
  leftarg   = double precision,
  rightarg  = double precision,
  procedure = dt_utils.approx_equals);

----------------------------------------------------------------------------------------------------
-- Interval parameterization as [yy, mm, dd, hh, mi, ss]

create type dt_utils.interval_parameterization_t as(
  yy double precision,
  mm double precision,
  dd double precision,
  hh double precision,
  mi double precision,
  ss double precision);
revoke all   on type dt_utils.interval_parameterization_t from public;
grant  usage on type dt_utils.interval_parameterization_t to   public;

create function dt_utils.interval_parameterization(
  yy in double precision default 0,
  mm in double precision default 0,
  dd in double precision default 0,
  hh in double precision default 0,
  mi in double precision default 0,
  ss in double precision default 0)
  returns dt_utils.interval_parameterization_t
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  ok constant boolean :=
    (yy is not null) and
    (mm is not null) and
    (dd is not null) and
    (hh is not null) and
    (mi is not null) and
    (ss is not null);
  p interval_parameterization_t not null :=
   (yy, mm, dd, hh, mi, ss)::interval_parameterization_t;
begin
  assert ok, 'No argument, when provided, may be null';
  return p;
end;
$body$;
revoke all     on function dt_utils.interval_parameterization(
  double precision, double precision, double precision, double precision, double precision, double precision) from public;
grant  execute on function dt_utils.interval_parameterization(
  double precision, double precision, double precision, double precision, double precision, double precision) to   public;

----------------------------------------------------------------------------------------------------
-- Create an actual interval value from [yy, mm, dd, hh, mi, ss].

create function dt_utils.interval_value(p in dt_utils.interval_parameterization_t)
  returns interval
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  yy constant interval not null := p.yy::text ||' years';
  mm constant interval not null := p.mm::text ||' months';
  dd constant interval not null := p.dd::text ||' days';
  hh constant interval not null := p.hh::text ||' hours';
  mi constant interval not null := p.mi::text ||' minutes';
  ss constant interval not null := p.ss::text ||' seconds';
begin  
  return yy + mm + dd + hh + mi + ss;
end;
$body$;
revoke all     on function dt_utils.interval_value(dt_utils.interval_parameterization_t) from public;
grant  execute on function dt_utils.interval_value(dt_utils.interval_parameterization_t) to   public;

----------------------------------------------------------------------------------------------------
-- Extract [yy, mm, dd, hh, mi, ss] from an actual interval value.

create function dt_utils.parameterization(i in interval)
  returns dt_utils.interval_parameterization_t
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  -- All but the seconds value are always integral.
  yy  double precision not null := round(extract(years   from i));
  mm  double precision not null := round(extract(months  from i));
  dd  double precision not null := round(extract(days    from i));
  hh  double precision not null := round(extract(hours   from i));
  mi  double precision not null := round(extract(minutes from i));
  ss  double precision not null :=       extract(seconds from i);
begin
  return (yy, mm, dd, hh, mi, ss)::interval_parameterization_t;
end;
$body$;
revoke all     on function dt_utils.parameterization(interval) from public;
grant  execute on function dt_utils.parameterization(interval) to   public;

----------------------------------------------------------------------------------------------------
-- Test a pair of "interval_parameterization_t values" for equality.
-- The function parameterization(i in interval) returns interval_parameterization_t
-- uses "extract()" and this accesses the internal [mm, dd, ss] representation.
-- There's a risk of rounding errors here. For example, when the ss field corresponds
-- to 04:48:00, this might be extracted as 04:47,59.99999999...
-- The "approx_equals()" test needs to accommodate this.

create function dt_utils.approx_equals(
  p1_in in dt_utils.interval_parameterization_t,
  p2_in in dt_utils.interval_parameterization_t)
  returns boolean
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  -- There's no need (for the present pedagogical purpose) to extend this to
  -- handle NULL inputs. It would be simple to do this.
  p1    constant interval_parameterization_t not null := p1_in;
  p2    constant interval_parameterization_t not null := p2_in;

  mons1 constant double precision            not null := p1.yy*12.0 + p1.mm;
  mons2 constant double precision            not null := p2.yy*12.0 + p2.mm;

  secs1 constant double precision            not null := p1.hh*60.0*60.0 + p1.mi*60.0 + p1.ss;
  secs2 constant double precision            not null := p2.hh*60.0*60.0 + p2.mi*60.0 + p2.ss;

  eq    constant boolean                     not null := (mons1 ~= mons2) and
                                                         (p1.dd ~= p2.dd) and
                                                         (secs1 ~= secs2);
begin
  return eq;
end;
$body$;
revoke all     on function dt_utils.approx_equals(dt_utils.interval_parameterization_t, dt_utils.interval_parameterization_t) from public;
grant  execute on function dt_utils.approx_equals(dt_utils.interval_parameterization_t, dt_utils.interval_parameterization_t) to   public;

create operator dt_utils.~= (
  leftarg   = dt_utils.interval_parameterization_t,
  rightarg  = dt_utils.interval_parameterization_t,
  procedure = dt_utils.approx_equals);

----------------------------------------------------------------------------------------------------
-- Model an interval as a UDT [mm, dd, ss] tuple.
create type dt_utils.interval_mm_dd_ss_t as(mm int, dd int, ss double precision);
revoke all   on type dt_utils.interval_mm_dd_ss_t from public;
grant  usage on type dt_utils.interval_mm_dd_ss_t to   public;

-- Create an interval_mm_dd_ss_t value from an actual interval value
create function dt_utils.interval_mm_dd_ss(i in interval)
  returns dt_utils.interval_mm_dd_ss_t
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
begin
  if i is null then
    return null;
  else
    declare
      mm  constant int              not null := (extract(years from i))*12 +
                                                 extract(months from i);

      dd  constant int              not null := extract(days from i);

      ss  constant double precision not null := (extract(hours   from i))*60*60 +
                                                 extract(minutes from i)*60 +
                                                 extract(seconds from i);
    begin
      return (mm, dd, ss);
    end;
  end if;
end;
$body$;
revoke all     on function dt_utils.interval_mm_dd_ss(interval) from public;
grant  execute on function dt_utils.interval_mm_dd_ss(interval) to   public;

create function dt_utils.approx_equals(
  i1_in in dt_utils.interval_mm_dd_ss_t,
  i2_in in dt_utils.interval_mm_dd_ss_t)
  returns boolean
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  -- There's no need (for the present pedagogical purpose) to extend this to
  -- handle NULL inputs. It would be simple to do this.
  i1 constant interval_mm_dd_ss_t not null := i1_in;
  i2 constant interval_mm_dd_ss_t not null := i2_in;
  eq constant boolean             not null := (i1.mm = i2.mm) and
                                              (i1.dd = i2.dd) and
                                              (i1.ss ~= i2.ss);
begin
  return eq;
end;
$body$;
revoke all     on function dt_utils.approx_equals(dt_utils.interval_mm_dd_ss_t, dt_utils.interval_mm_dd_ss_t) from public;
grant  execute on function dt_utils.approx_equals(dt_utils.interval_mm_dd_ss_t, dt_utils.interval_mm_dd_ss_t) to   public;

create operator dt_utils.~= (
  leftarg   = dt_utils.interval_mm_dd_ss_t,
  rightarg  = dt_utils.interval_mm_dd_ss_t,
  procedure = dt_utils.approx_equals);

----------------------------------------------------------------------------------------------------
-- Create an actual interval value from [mm, dd, ss].
create function dt_utils.interval_value(i in dt_utils.interval_mm_dd_ss_t)
  returns interval
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
begin  
  return make_interval(months=>i.mm, days=>i.dd, secs=>i.ss);
end;
$body$;
revoke all     on function dt_utils.interval_value(dt_utils.interval_mm_dd_ss_t) from public;
grant  execute on function dt_utils.interval_value(dt_utils.interval_mm_dd_ss_t) to   public;

----------------------------------------------------------------------------------------------------
-- Extract [yy, mm, dd, hh, mi, ss] parameterization from a [mm, dd, ss] tuple.

create function dt_utils.parameterization(i in dt_utils.interval_mm_dd_ss_t)
  returns dt_utils.interval_parameterization_t
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  yy  constant int              := trunc(i.mm/12);
  mm  constant int              := i.mm - yy*12;
  dd  constant int              := i.dd;
  hh  constant int              := trunc(i.ss/(60.0*60.0));
  mi  constant int              := trunc((i.ss - hh*60.0*60)/60.0);
  ss  constant double precision := i.ss - (hh*60.0*60.0 + mi*60.0);
begin
  return (yy, mm, dd, hh, mi, ss)::interval_parameterization_t;
end;
$body$;
revoke all     on function dt_utils.parameterization(dt_utils.interval_mm_dd_ss_t) from public;
grant  execute on function dt_utils.parameterization(dt_utils.interval_mm_dd_ss_t) to   public;

----------------------------------------------------------------------------------------------------

create function dt_utils.justified_seconds(i in interval)
  returns double precision
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
begin
  if i is null then
    return null;
  else
    declare
      secs_pr_day    constant double precision     not null := 24*60*60;
      secs_pr_month  constant double precision     not null := secs_pr_day*30;

      r              constant interval_mm_dd_ss_t  not null := interval_mm_dd_ss(i);
      ss             constant double precision     not null := r.ss + r.dd*secs_pr_day + r.mm*secs_pr_month;

      rj             constant interval_mm_dd_ss_t  not null := interval_mm_dd_ss(justify_interval(i));
      ssj            constant double precision              not null := rj.ss + rj.dd*secs_pr_day + rj.mm*secs_pr_month;
    begin
      assert ss = ssj, 'justified_seconds(): assert failed';
      return ss;
    end;
  end if;
end;
$body$;
revoke all     on function dt_utils.justified_seconds(interval) from public;
grant  execute on function dt_utils.justified_seconds(interval) to   public;

----------------------------------------------------------------------------------------------------

create function dt_utils.strict_equals(i1 in interval, i2 in interval)
  returns boolean
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
begin
  if i1 is null or i2 is null then
    return null;
  else
    declare
      mm_dd_ss_1 constant interval_mm_dd_ss_t not null := interval_mm_dd_ss(i1);
      mm_dd_ss_2 constant interval_mm_dd_ss_t not null := interval_mm_dd_ss(i2);
    begin
      return mm_dd_ss_1 ~= mm_dd_ss_2;
    end;
  end if;
end;
$body$;
revoke all     on function dt_utils.strict_equals(interval, interval) from public;
grant  execute on function dt_utils.strict_equals(interval, interval) to   public;

create operator dt_utils.== (
  leftarg   = interval,
  rightarg  = interval,
  procedure = dt_utils.strict_equals);

----------------------------------------------------------------------------------------------------
-- Notice that there is no native plain timestamp eqivalent of to_timestamp().
create function dt_utils.to_timestamp_without_tz(ss_from_epoch in double precision)
  returns /* plain */ timestamp
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  current_tz text not null := '';
begin
  -- Save present setting.
  -- OR select current_setting('TimeZone');
  show timezone into current_tz;
  assert length(current_tz) > 0, 'undefined time zone';
  set timezone = 'UTC';
  declare
    t_tz constant timestamptz := to_timestamp(ss_from_epoch);
    t    constant timestamp   := t_tz at time zone 'UTC';
  begin
    -- Restore the saved time zone setting.
    execute 'set timezone = '''||current_tz||'''';
    return t;
  end;
end;
$body$;
revoke all     on function dt_utils.to_timestamp_without_tz(double precision) from public;
grant  execute on function dt_utils.to_timestamp_without_tz(double precision) to   public;

----------------------------------------------------------------------------------------------------
-- Notice that there is no native to_time().

-- mod() doesn't have an overload for "double precision" arguments.
create function dt_utils.to_time(ss in double precision)
  returns time
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  -- Notice the ss value can be bigger than ss_per_day.
  ss_per_day        constant  numeric          not null := 24.0*60.0*60.0;
  ss_from_midnight  constant  double precision not null := mod(ss::numeric, ss_per_day);
  t                 constant  time             not null :=
                      make_interval(secs=>ss_from_midnight)::time;
begin
  return t;
end;
$body$;
revoke all     on function dt_utils.to_time(double precision) from public;
grant  execute on function dt_utils.to_time(double precision) to   public;
