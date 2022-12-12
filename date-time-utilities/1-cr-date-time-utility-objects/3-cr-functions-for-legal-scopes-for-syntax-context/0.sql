create type ext_tz_names.occurrences_t as(
  names_name      boolean,
  names_abbrev    boolean,
  abbrevs_abbrev  boolean);
----------------------------------------------------------------------------------------------------

create function ext_tz_names.occurrences(string in text)
  returns ext_tz_names.occurrences_t
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  names_name_count constant int not null :=
    (select count(*) from pg_timezone_names   where upper(name)   = upper(string));
  names_abbrev_count constant int not null :=
    (select count(*) from pg_timezone_names   where upper(abbrev) = upper(string));
  abbrevs_abbrev_count constant int not null :=
    (select count(*) from pg_timezone_abbrevs where upper(abbrev) = upper(string));
  r constant ext_tz_names.occurrences_t not null := (
    names_name_count     > 0,
    names_abbrev_count   > 0,
    abbrevs_abbrev_count > 0)::ext_tz_names.occurrences_t;
begin
  return r;
end;
$body$;
----------------------------------------------------------------------------------------------------

create function ext_tz_names.legal_scopes_for_syntax_context(string in text)
  returns table(x text)
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  ok                       constant text          not null := '> OK';
  x1                       constant text          not null := '> invalid_parameter_value';
  x2                       constant text          not null := '> invalid_datetime_format';
  set_timezone_            constant text          not null := $$set timezone = '%s'$$;
  timezone_invocation_     constant text          not null := $$select timezone('%s', '%s')$$;
  timestamptz_literal_     constant text          not null := $$select '%s %s'::timestamptz$$;

  ts_plain                 constant timestamp     not null := '2021-06-07 12:00:00';
  ts_text                  constant text          not null := ts_plain::text;
  ts_tz                             timestamptz   not null := now();

  set_timezone             constant text          not null := format(set_timezone_, string);
  timezone_invocation      constant text          not null := format(timezone_invocation_, string, ts_plain);
  timestamptz_literal      constant text          not null := format(timestamptz_literal_, ts_plain, string);

  set_timezone_msg         constant text          not null := rpad(set_timezone            ||';', 61);
  timezone_invocation_msg  constant text          not null := rpad(timezone_invocation     ||';', 61);
  timestamptz_literal_msg  constant text          not null := rpad(timestamptz_literal     ||';', 61);

  occurrences              constant ext_tz_names.occurrences_t not null := ext_tz_names.occurrences(string);
begin
  x := rpad(string||':', 20)                               ||
       'names_name: '    ||occurrences.names_name    ::text||' / '||
       'names_abbrev: '  ||occurrences.names_abbrev  ::text||' / '||
       'abbrevs_abbrev: '||occurrences.abbrevs_abbrev::text;                            return next;
  x := rpad('-', 90, '-');                                                              return next;

  -- "set timezone"
  begin
    execute set_timezone;
    x := set_timezone_msg||ok;                                                          return next;
  exception when invalid_parameter_value then
    x := set_timezone_msg||x1;                                                          return next;
  end;

  -- "at timezone"
  begin
    execute timezone_invocation into ts_tz;
    x := timezone_invocation_msg||ok;                                                   return next;
  exception when invalid_parameter_value then
    x := timezone_invocation_msg||x1;                                                   return next;
  end;

  begin
    execute timestamptz_literal into ts_tz;
    x := timestamptz_literal_msg||ok;                                                   return next;
  exception when invalid_datetime_format then
    x := timestamptz_literal_msg||x2;                                                   return next;
  end;
end;
$body$;
