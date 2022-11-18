create procedure ext_tz_names.assert_approved_timezone_name(tz in text)
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  bad constant boolean not null :=
    (select count(*) from ext_tz_names.approved_timezone_names where lower(name) = lower(tz)) <> 1;
begin
  if bad then
    declare
      code  constant text not null := '22023';
      msg   constant text not null := 'Invalid value for parameter TimeZone "'||tz||'"';
      hint  constant text not null := 'Use a name that''s found exactly once in "approved_timezone_names"';
    begin
      raise exception using
        errcode = code,
        message = msg,
        hint    = hint;
    end;
  end if;
end;
$body$;
call mgr.revoke_all_from_public('procedure', 'ext_tz_names.assert_approved_timezone_name(text)');
call mgr.grant_priv( 'execute', 'procedure', 'ext_tz_names.assert_approved_timezone_name(text)', 'public');
