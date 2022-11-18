-- plain timestamp in, timestamptz out.
create function ext_tz_names.at_timezone(tz in text, t in timestamp)
  returns timestamptz
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
begin
  call ext_tz_names.assert_approved_timezone_name(tz);
  return timezone(tz, t);
end;
$body$;
call mgr.revoke_all_from_public('function', 'ext_tz_names.at_timezone(text, timestamp)');
call mgr.grant_priv( 'execute', 'function', 'ext_tz_names.at_timezone(text, timestamp)', 'public');


-- This overload is almost textually identical to the preceding one.
-- The data types of the second formal and the return have
-- simply been exchanged.
-- timestamptz in, plain timestamp out.
create function ext_tz_names.at_timezone(tz in text, t in timestamptz)
  returns timestamp
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
begin
  call ext_tz_names.assert_approved_timezone_name(tz);
  return timezone(tz, t);
end;
$body$;
call mgr.revoke_all_from_public('function', 'ext_tz_names.at_timezone(text, timestamptz)');
call mgr.grant_priv( 'execute', 'function', 'ext_tz_names.at_timezone(text, timestamptz)', 'public');

-- interval in, timestamptz out.
create function ext_tz_names.at_timezone(i in interval, t in timestamp)
  returns timestamptz
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
begin
  call ext_tz_names.assert_acceptable_timezone_interval(i);
  return timezone(i, t);
end;
$body$;
call mgr.revoke_all_from_public('function', 'ext_tz_names.at_timezone(interval, timestamp)');
call mgr.grant_priv( 'execute', 'function', 'ext_tz_names.at_timezone(interval, timestamp)', 'public');


-- This overload is almost textually identical to the preceding one.
-- The data types of the second formal and the return have
-- simply been exchanged.
-- interval in, plain timestamp out.
create function ext_tz_names.at_timezone(i in interval, t in timestamptz)
  returns timestamp
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
begin
  call ext_tz_names.assert_acceptable_timezone_interval(i);
  return timezone(i, t);
end;
$body$;
call mgr.revoke_all_from_public('function', 'ext_tz_names.at_timezone(interval, timestamptz)');
call mgr.grant_priv( 'execute', 'function', 'ext_tz_names.at_timezone(interval, timestamptz)', 'public');
