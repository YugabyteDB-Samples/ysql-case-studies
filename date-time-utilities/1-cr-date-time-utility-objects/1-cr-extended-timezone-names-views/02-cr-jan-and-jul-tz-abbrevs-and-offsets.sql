create function ext_tz_names.jan_and_jul_tz_abbrevs_and_offsets()
  returns table(
  name        text,
  jan_abbrev  text,
  jul_abbrev  text,
  jan_offset  interval,
  jul_offset  interval)
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  set_timezone constant text not null := 'set timezone = %L';
  tz_set                text not null := '';
  tz_on_entry  constant text not null := current_setting('timezone');
begin
  for tz_set in (
    select pg_timezone_names.name as a
    from pg_timezone_names
  ) loop
    execute format(set_timezone, tz_set);
    select
      current_setting('timezone'),
      to_char('2021-01-01 12:00:00 UTC'::timestamptz, 'TZ'),
      to_char('2021-07-01 12:00:00 UTC'::timestamptz, 'TZ'),
      to_char('2021-01-01 12:00:00 UTC'::timestamptz, 'TZH:TZM')::interval,
      to_char('2021-07-01 12:00:00 UTC'::timestamptz, 'TZH:TZM')::interval
    into
      name,
      jan_abbrev,
      jul_abbrev,
      jan_offset,
      jul_offset;
    return next;
  end loop;

  execute format(set_timezone, tz_on_entry);
end;
$body$;

call mgr.revoke_all_from_public('function', 'ext_tz_names.jan_and_jul_tz_abbrevs_and_offsets()');
call mgr.grant_priv( 'execute', 'function', 'ext_tz_names.jan_and_jul_tz_abbrevs_and_offsets()', 'public');
