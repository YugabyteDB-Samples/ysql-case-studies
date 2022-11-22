create function mgr.drop_tenant_databases_script(
  filename     in text,
  lower_db_no  in int = 0,
  upper_db_no  in int = 0)
  returns table(z text)
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  dbs_for_deletion name[] := '{}'::name[];
begin
  assert upper_db_no >= lower_db_no, 'upper_db_no < lower_db_no';

  if upper_db_no > lower_db_no then
    for j in lower_db_no..upper_db_no loop
      dbs_for_deletion[j] := 'd'||j::text;
    end loop;
  end if;

  declare
    d            text  not null := '';
    ds constant text[] :=
      case
        when cardinality(dbs_for_deletion) = 0 then
          (
            select array_agg(datname)
            from pg_database
            where not datistemplate
            and   not (datname in ('postgres', 'system_platform'))
          )
        else
          (
            select array_agg(datname)
            from pg_database
            where datname = any(dbs_for_deletion)
          )
      end;
  begin
    if not (ds is null or cardinality(ds) < 1) then
      z :=          $$  \c postgres clstr$mgr                                               $$;     return next;
      foreach d in array ds loop
        z := format($$  alter database %I with allow_connections false connection limit 0;  $$, d); return next;
      end loop;
      z :=                                                                                  '';     return next;
      foreach d in array ds loop
        z := format($$  call mgr.kill_all_sessions_for_specified_database(%L);              $$, d); return next;
        z := format($$  drop database %I;                                                   $$, d); return next;
        z :=                                                                                '';     return next;
      end loop;
    end if;

    -- Have this script remove itself when it has been executed.
    -- "rm -Rf" suppresses error messages when nothing to delete.
    z := format('\! rm -Rf %s', filename);                                                          return next;
  end;
end;
$body$;

revoke all on function mgr.drop_tenant_databases_script(text, int, int) from public;
