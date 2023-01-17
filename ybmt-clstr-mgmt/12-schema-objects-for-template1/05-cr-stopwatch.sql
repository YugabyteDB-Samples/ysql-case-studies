/*
  See this section in the YSQL documentation:
  Case study: implementing a stopwatch with SQL
  https://docs.yugabyte.com/preview/api/ysql/datatypes/type_datetime/stopwatch/

  and this blog post:
  https://www.yugabyte.com/blog/a-sql-stopwatch-utility-for-yugabytedb-or-postgresql-as-an-alternative-for-timing-on/
*/;
create function client_safe.fmt(n in numeric, template in text)
  returns text
  stable
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
begin
  return ltrim(to_char(n, template));
end;
$body$;

grant execute on function client_safe.fmt(numeric, text) to public;
----------------------------------------------------------------------------------------------------

create function client_safe.fmt(i in int, template in text)
  returns text
  stable
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
begin
  return ltrim(to_char(i, template));
end;
$body$;

grant execute on function client_safe.fmt(int, text) to public;
----------------------------------------------------------------------------------------------------

create function client_safe.duration_as_text(t in numeric)
  returns text
  stable
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  ms_pr_sec         constant numeric not null := 1000.0;
  secs_pr_min       constant numeric not null := 60.0;
  mins_pr_hour      constant numeric not null := 60.0;
  secs_pr_hour      constant numeric not null := mins_pr_hour*secs_pr_min;
  secs_pr_day       constant numeric not null := 24.0*secs_pr_hour;

  confidence_limit  constant numeric not null := 0.02;
  ms_limit          constant numeric not null := 5.0;
  cs_limit          constant numeric not null := 10.0;

  result                     text    not null := '';
begin
  case
    when t < confidence_limit then
      result := 'less than ~20 ms';

    when t >= confidence_limit and t < ms_limit then
      result := client_safe.fmt(t*ms_pr_sec, '9999')||' ms';

    when t >= ms_limit and t < cs_limit then
      result := client_safe.fmt(t, '90.99')||' ss';

    when t >= cs_limit and t < secs_pr_min then
      result := client_safe.fmt(t, '99.9')||' ss';

    when t >= secs_pr_min and t < secs_pr_hour then
      declare
        ss   constant numeric not null := round(t);
        mins constant int     not null := trunc(ss/secs_pr_min);
        secs constant int     not null := ss - mins*secs_pr_min;
      begin
        result := client_safe.fmt(mins, '09')||':'||client_safe.fmt(secs, '09')||' mi:ss';
      end;

    when t >= secs_pr_hour and t < secs_pr_day then
      declare
        mi    constant numeric not null := round(t/secs_pr_min);
        hours constant int     not null := trunc(mi/mins_pr_hour);
        mins  constant int     not null := round(mi - hours*mins_pr_hour);
      begin
        result := client_safe.fmt(hours, '09')||':'||client_safe.fmt(mins,  '09')||' hh:mi';
      end;

    when t >= secs_pr_day then
      declare
        days   constant int     not null := trunc(t/secs_pr_day);
        mi     constant numeric not null := (t - days*secs_pr_day)/secs_pr_min;
        hours  constant int     not null := trunc(mi/mins_pr_hour);
        mins   constant int     not null := round(mi - hours*mins_pr_hour);
      begin
        result := client_safe.fmt(days,  '99')||' days '||
                  client_safe.fmt(hours, '09')||':'||client_safe.fmt(mins,  '09')||' hh:mi';
      end;
  end case;
  return result;
end;
$body$;

grant execute on function client_safe.duration_as_text(numeric) to public;
----------------------------------------------------------------------------------------------------

create procedure client_safe.start_stopwatch()
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  -- Make a memo of the current wall-clock time as (real) seconds
  -- since midnight on 1-Jan-1970.
  start_time constant text not null := extract(epoch from clock_timestamp())::text;
begin
  execute format('set stopwatch.start_time to %L', start_time);
end;
$body$;

grant execute on procedure client_safe.start_stopwatch() to public;
----------------------------------------------------------------------------------------------------

create function client_safe.stopwatch_reading_as_dp()
  returns double precision
  -- It's critical to use "volatile" because "clock_timestamp()" is volatile.
  -- "volatile" is the default. Spelled out here for self-doc.
  volatile
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  start_time  constant double precision not null := current_setting('stopwatch.start_time');
  curr_time   constant double precision not null := extract(epoch from clock_timestamp());
  diff        constant double precision not null := curr_time - start_time;
begin
  return diff;
end;
$body$;

grant execute on function client_safe.stopwatch_reading_as_dp() to public;
----------------------------------------------------------------------------------------------------

create function client_safe.stopwatch_reading()
  returns text
  -- It's critical to use "volatile" because "stopwatch_reading_as_dp()" is volatile.
  volatile
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  t constant text not null := client_safe.duration_as_text(client_safe.stopwatch_reading_as_dp()::numeric);
begin
  return t;
end;
$body$;

grant execute on function client_safe.stopwatch_reading() to public;
----------------------------------------------------------------------------------------------------

/*
  "pg_typeof(extract(epoch from clock_timestamp()))" evaluates to "double precision".
  That's why this function has a "double precision" input formal parameter.
  The arithmetic
*/
create function client_safe.stopwatch_reading(start_time in double precision)
  returns text
  volatile
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  curr_time  constant double precision not null := extract(epoch from clock_timestamp());
  diff       constant double precision not null := curr_time - start_time;
begin
  return client_safe.duration_as_text(diff::numeric);
end;
$body$;

grant execute on function client_safe.stopwatch_reading(double precision) to public;
----------------------------------------------------------------------------------------------------
/*
  "pg_typeof(1672249774.83485)"  evaluates to "numeric". So this invocation:

     client_safe.stopwatch_reading(start_time=>1672249774.83485)

  would imply a data type conversion in the caller env were it not for
  the existence of this explict "numeric" overload.

  The "numeric" overload simply documents what anyway would happen.
*/
create function client_safe.stopwatch_reading(start_time in numeric)
  returns text
  volatile
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
begin
  return client_safe.stopwatch_reading(start_time::double precision);
end;
$body$;

grant execute on function client_safe.stopwatch_reading(double precision) to public;
