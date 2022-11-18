create procedure ext_tz_names.set_timezone(tz in text)
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
begin
  call ext_tz_names.assert_approved_timezone_name(tz);
  declare
    stmt constant text not null := 'set timezone = '''||tz||'''';
  begin
    execute stmt;
  end;
end;
$body$;
call mgr.revoke_all_from_public('procedure', 'ext_tz_names.set_timezone(text)');
call mgr.grant_priv( 'execute', 'procedure', 'ext_tz_names.set_timezone(text)', 'public');

create procedure ext_tz_names.set_timezone(i in interval)
  language plpgsql
as $body$
begin
  call ext_tz_names.assert_acceptable_timezone_interval(i);
  declare
    stmt constant text not null := 'set time zone interval '''||i::text||'''';
  begin
    execute stmt;
  end;
end;
$body$;
call mgr.revoke_all_from_public('procedure', 'ext_tz_names.set_timezone(interval)');
call mgr.grant_priv( 'execute', 'procedure', 'ext_tz_names.set_timezone(interval)', 'public');
