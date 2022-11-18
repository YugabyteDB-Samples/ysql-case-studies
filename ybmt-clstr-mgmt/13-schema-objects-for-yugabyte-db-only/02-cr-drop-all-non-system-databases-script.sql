/*
  This is first created with owner "yugabyte". Then, after its first use, it's
  re-created with owner "clstr$mgr". See the comment in
  "01-kill-all-sessions-for-specified-database.sql".
*/;
create function mgr.drop_all_non_system_databases_script(filename in text)
  returns table(z text)
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  d           text  not null := '';
  ds constant text[] :=
    (
      select array_agg(datname)
      from pg_database
      where not datistemplate
      and       datname != 'yugabyte'
      and       datname != 'system_platform');
begin
  case
    when ds is null or cardinality(ds) < 1 then
      z := '';                                                                return next;
    else
      foreach d in array ds loop
        z := format('alter database %I with allow_connections false;', d);    return next;
      end loop;

      -- Just in case a session has started since all were killed.
      -- Using the default means "all".
      z := 'call mgr.kill_all_sessions_for_specified_database();';            return next;

      foreach d in array ds loop
        z := format('drop database %I;', d);                                  return next;
      end loop;
  end case;

  -- Have this script remove itself when it has been executed.
  -- "rm -Rf" suppresses error messages when nothing to delete.
  z := format('\! rm -Rf %s', filename);                                      return next;
end;
$body$;

revoke all on function mgr.drop_all_non_system_databases_script(text) from public;
