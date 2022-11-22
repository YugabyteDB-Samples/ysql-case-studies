/*
  This will be owned by the "postgres" superuser. See the PG doc:

    www.postgresql.org/docs/11/runtime-config-logging.html

  "Only superusers can change this setting."
*/;
create procedure mgr.set_tenant_database_setting(db in text, setting in text, val in text)
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
begin
  execute format('alter database %I set %s = %L;', current_database(), setting, val);
end;
$body$;

revoke all on procedure mgr.set_tenant_database_setting(text, text, text) from public;
