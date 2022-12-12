-- Error "23514" is pre-defined and mapped to "check_violation".

-- =============================================================================
-- CREATE THE DOMAINS

-- interval_months_t

create function dt_utils.mm_value_ok(mm in int)
  returns text
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  max_mm constant bigint not null := 3587867;
begin
  return
    case abs(mm) > max_mm
      when true then 'Bad mm: '||mm::text||'. Must be in [-'||max_mm||', '||max_mm||'].'
      else           ''
    end;
end;
$body$;

create function dt_utils.interval_months_ok(i in interval)
  returns boolean
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
begin
  if i is null then
    return true;
  else
    declare
      mm_dd_ss       constant interval_mm_dd_ss_t not null := interval_mm_dd_ss(i);
      mm             constant int                 not null := mm_dd_ss.mm;
      dd             constant int                 not null := mm_dd_ss.dd;
      ss             constant double precision    not null := mm_dd_ss.ss;
      chk_violation  constant text                not null := '23514';
      msg            constant text                not null :=
                       'value for domain interval_months_t violates check constraint "interval_months_ok".';
    begin
      if dd <> 0 or ss <> 0.0 then
        begin
          raise exception using
            errcode = chk_violation,
            message = msg,
            hint    = case
                        when dd <> 0 and ss <> 0.0 then  'dd = '||dd::text||'. ss = '||ss::text||'. Both must be zero'
                        when dd <> 0               then  'dd = '||dd::text||'. Both dd and ss must be zero'
                        when             ss <> 0.0 then  'ss = '||ss::text||'. Both dd and ss must be zero'
                      end;
        end;
      end if;

      declare
        hint constant text not null := mm_value_ok(mm);
      begin
        if hint <> '' then
          raise exception using
            errcode = chk_violation,
            message = msg,
            hint    = hint;
        end if;
      end;

      return true;
    end;
  end if;
end;
$body$;

create domain dt_utils.interval_months_t as interval
constraint interval_months_ok check(dt_utils.interval_months_ok(value));

----------------------------------------
-- interval_days_t

create function dt_utils.dd_value_ok(dd in int)
  returns text
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  max_dd constant bigint not null := 109203489;
begin
  return
    case abs(dd) > max_dd
      when true then 'Bad dd: '||dd::text||'. Must be in [-'||max_dd||', '||max_dd||'].'
      else           ''
    end;
end;
$body$;

create function dt_utils.interval_days_ok(i in interval)
  returns boolean
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
begin
  if i is null then
    return true;
  else
    declare
      mm_dd_ss       constant interval_mm_dd_ss_t not null := interval_mm_dd_ss(i);
      mm             constant int                              not null := mm_dd_ss.mm;
      dd             constant int                              not null := mm_dd_ss.dd;
      ss             constant double precision                 not null := mm_dd_ss.ss;
      chk_violation  constant text                             not null := '23514';
      msg            constant text                             not null :=
                       'value for domain interval_days_t violates check constraint "interval_days_ok".';
    begin
      if mm <> 0 or ss <> 0.0 then
        begin
          raise exception using
            errcode = chk_violation,
            message = msg,
            hint    = case
                        when mm <> 0 and ss <> 0.0 then  'mm = '||mm::text||'. ss = '||ss::text||'. Both must be zero'
                        when mm <> 0               then  'mm = '||mm::text||'. Both mm and ss must be zero'
                        when             ss <> 0.0 then  'ss = '||ss::text||'. Both mm and ss must be zero'
                      end;
        end;
      end if;

      declare
        hint constant text not null := dd_value_ok(dd);
      begin
        if hint <> '' then
          raise exception using
            errcode = chk_violation,
            message = msg,
            hint    = hint;
        end if;
      end;

      return true;
    end;
  end if;
end;
$body$;

create domain dt_utils.interval_days_t as interval
constraint interval_days_ok check(dt_utils.interval_days_ok(value));

----------------------------------------
-- interval_seconds_t

create function dt_utils.ss_value_ok(ss in double precision)
  returns text
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  max_ss constant double precision not null := 7730941132799.0;
begin
  return
    case abs(ss) > max_ss
      when true then 'Bad ss: '||ss::text||'. Must be in [-'||max_ss||', '||max_ss||'].'
      else           ''
    end;
end;
$body$;

create function dt_utils.interval_seconds_ok(i in interval)
  returns boolean
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
begin
  if i is null then
    return true;
  else
    declare
      mm_dd_ss       constant interval_mm_dd_ss_t not null := interval_mm_dd_ss(i);
      mm             constant int                 not null := mm_dd_ss.mm;
      dd             constant int                 not null := mm_dd_ss.dd;
      ss             constant double precision    not null := mm_dd_ss.ss;
      chk_violation  constant text                not null := '23514';
      msg            constant text                not null :=
                       'value for domain interval_seconds_t violates check constraint "interval_seconds_ok".';
    begin
      if mm <> 0 or dd <> 0 then
        begin
          raise exception using
            errcode = chk_violation,
            message = msg,
            hint    = case
                        when mm <> 0 and dd <> 0 then  'mm = '||mm::text||'. dd = '||dd::text||'. Both must be zero'
                        when mm <> 0             then  'mm = '||mm::text||'. Both mm and dd must be zero'
                        when             dd <> 0 then  'dd = '||dd::text||'. Both mm and dd must be zero'
                      end;
        end;
      end if;

      declare
        hint constant text not null := ss_value_ok(ss);
      begin
        if hint <> '' then
          raise exception using
            errcode = chk_violation,
            message = msg,
            hint    = hint;
        end if;
      end;

      return true;
    end;
  end if;
end;
$body$;

create domain dt_utils.interval_seconds_t as interval
constraint interval_seconds_ok check(dt_utils.interval_seconds_ok(value));

-- =============================================================================
-- IMPLEMENT THE FUNCTIONALITY

-- interval_months_t

create function dt_utils.interval_months(years in int default 0, months in int default 0)
  returns dt_utils.interval_months_t
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  mm             constant int  not null := years*12 + months;
  hint           constant text not null := mm_value_ok(mm);
  chk_violation  constant text not null := '23514';
  msg            constant text not null :=
                   'value for domain interval_months_t violates check constraint "interval_months_ok".';
begin
  if hint <> '' then
    raise exception using
      errcode = chk_violation,
      message = msg,
      hint    = hint;
  end if;
  return make_interval(years=>years, months=>months);
end;
$body$;

create function dt_utils.interval_months(t_finish in timestamptz, t_start in timestamptz)
  returns dt_utils.interval_months_t
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  finish_year   constant int     not null := extract(year  from t_finish);
  finish_month  constant int     not null := extract(month from t_finish);
  finish_AD_BC  constant text    not null := to_char(t_finish, 'BC');
  finish_is_BC  constant boolean not null :=
    case
      when finish_AD_BC = 'BC' then true
      when finish_AD_BC = 'AD' then false
    end;

  start_year   constant int not null := extract(year  from t_start);
  start_month  constant int not null := extract(month from t_start);
  start_AD_BC  constant text    not null := to_char(t_start, 'BC');
  start_is_BC  constant boolean not null :=
    case
      when start_AD_BC = 'BC' then true
      when start_AD_BC = 'AD' then false
    end;

  -- There is no "year zero". Therefore, when the two input moments straddle
  -- the AD/BC boundary, we must subtract 12 months to the computed months difference
  diff_as_months constant int not null :=
    (
      (finish_year*12 + finish_month)
      -
      (start_year*12  + start_month)
    )
    - case (finish_is_BC = start_is_BC)
        when true then 0
        else           12
      end;

  hint           constant text not null := mm_value_ok(diff_as_months);
  chk_violation  constant text not null := '23514';
  msg            constant text not null :=
                   'value for domain interval_months_t violates check constraint "interval_months_ok".';
begin
  -- You can reason that "interval_months(largest_legal_timestamptz_value, smallest_legal_timestamptz_value)"
  -- give mm = 3587867 and that because mm_value_ok() tests if this value is exceded, "hint" will always be
  -- the empty string and that the following test is unnecessary. It's done for symmetry and completeness.
  if hint <> '' then
    raise exception using
      errcode = chk_violation,
      message = msg,
      hint    = hint;
  end if;
  return interval_months(months=>diff_as_months);
end;
$body$;

create function dt_utils.interval_months(i in dt_utils.interval_months_t, f in double precision)
  returns dt_utils.interval_months_t
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  mm             constant double precision  not null := (interval_mm_dd_ss(i)).mm;
  mm_x_f         constant int               not null := round(mm*f);
  hint           constant text              not null := mm_value_ok(mm_x_f);
  chk_violation  constant text              not null := '23514';
  msg            constant text              not null :=
                   'value for domain interval_months_t violates check constraint "interval_months_ok".';
begin
  if hint <> '' then
    raise exception using
      errcode = chk_violation,
      message = msg,
      hint    = hint;
  end if;
  return interval_months(months=>mm_x_f);
end;
$body$;

----------------------------------------
-- interval_days_t

create function dt_utils.interval_days(days in int default 0)
  returns dt_utils.interval_days_t
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  hint           constant text not null := dd_value_ok(days);
  chk_violation  constant text not null := '23514';
  msg            constant text not null :=
                   'value for domain interval_days_t violates check constraint "interval_days_ok".';
begin
  if hint <> '' then
    raise exception using
      errcode = chk_violation,
      message = msg,
      hint    = hint;
  end if;
  return make_interval(days=>days);
end;
$body$;

create function dt_utils.interval_days(t_finish in timestamptz, t_start in timestamptz)
  returns dt_utils.interval_days_t
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  d_finish       constant date not null := t_finish::date;
  d_start        constant date not null := t_start::date;
  dd             constant int  not null := d_finish - d_start;
  hint           constant text not null := dd_value_ok(dd);
  chk_violation  constant text not null := '23514';
  msg            constant text not null :=
                   'value for domain interval_days_t violates check constraint "interval_days_ok".';
begin
  -- You can reason that "interval_days(largest_legal_timestamptz_value, smallest_legal_timestamptz_value)"
  -- give dd = 109203489 and that because dd_value_ok() tests if this value is exceded, "hint" will always be
  -- the empty string and that the following test is unnecessary. It's done for symmetry and completeness.
  if hint <> '' then
    raise exception using
      errcode = chk_violation,
      message = msg,
      hint    = hint;
  end if;
  return interval_days(days=>dd);
end;
$body$;

create function dt_utils.interval_days(i in dt_utils.interval_days_t, f in double precision)
  returns dt_utils.interval_days_t
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  dd             constant double precision not null := (interval_mm_dd_ss(i)).dd;
  dd_x_f         constant int              not null := round(dd*f);
  hint           constant text             not null := dd_value_ok(dd_x_f);
  chk_violation  constant text             not null := '23514';
  msg            constant text             not null :=
                   'value for domain interval_days_t violates check constraint "interval_days_ok".';
begin
  if hint <> '' then
    raise exception using
      errcode = chk_violation,
      message = msg,
      hint    = hint;
  end if;
  return interval_days(days=>dd_x_f);
end;
$body$;

----------------------------------------
-- interval_seconds_t

create function dt_utils.interval_seconds(
  hours in int              default 0,
  mins  in int              default 0,
  secs  in double precision default 0.0)
  returns dt_utils.interval_seconds_t
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  ss             constant double
                          precision not null := (hours::double precision)*60*60 + (mins::double precision)*60 + secs;
  hint           constant text not null := ss_value_ok(ss);
  chk_violation  constant text not null := '23514';
  msg            constant text not null :=
                   'value for domain interval_seconds_t violates check constraint "interval_seconds_ok".';
begin
  if hint <> '' then
    raise exception using
      errcode = chk_violation,
      message = msg,
      hint    = hint;
  end if;
  return make_interval(hours=>hours, mins=>mins, secs=>secs);
end;
$body$;

create function dt_utils.interval_seconds(t_finish in timestamptz, t_start in timestamptz)
  returns dt_utils.interval_seconds_t
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  s_finish       constant double precision not null := extract(epoch from t_finish);
  s_start        constant double precision not null := extract(epoch from t_start);
  ss             constant double precision not null := s_finish - s_start;
  hint           constant text not null := ss_value_ok(ss);
  chk_violation  constant text not null := '23514';
  msg            constant text not null :=
                   'value for domain interval_seconds_t violates check constraint "interval_seconds_ok".';
begin
  if hint <> '' then
    raise exception using
      errcode = chk_violation,
      message = msg,
      hint    = hint;
  end if;
  return interval_seconds(secs=>ss);
end;
$body$;

create function dt_utils.interval_seconds(i in dt_utils.interval_seconds_t, f in double precision)
  returns dt_utils.interval_seconds_t
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  ss             constant double precision not null := (interval_mm_dd_ss(i)).ss;
  ss_x_f         constant double precision not null := ss*f;
  hint           constant text             not null := ss_value_ok(ss_x_f);
  chk_violation  constant text             not null := '23514';
  msg            constant text             not null :=
                   'value for domain interval_seconds_t violates check constraint "interval_seconds_ok".';
begin
  if hint <> '' then
    raise exception using
      errcode = chk_violation,
      message = msg,
      hint    = hint;
  end if;
  return interval_seconds(secs=>ss_x_f);
end;
$body$;
