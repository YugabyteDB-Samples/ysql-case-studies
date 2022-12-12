create function mgr.drop_tenant_databases_script(
  filename     in text,
  lower_db_no  in int,
  upper_db_no  in int)
  returns table(z text)
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  db_name          text   not null := '';
  dbs_for_deletion name[] not null := '{}'::name;
begin
  assert
    lower_db_no >= 0 and
    upper_db_no >= 0 and
    upper_db_no >= lower_db_no, 'Require "upper_db_no >= lower_db_no" and both >= 0';

  for j in lower_db_no..upper_db_no loop
    db_name := 'd'||j::text;
    -- Sanity check.
    assert mgr.is_good_db_name(db_name), 'Bad tenant database name: '||db_name;
    dbs_for_deletion[j] := db_name::name;
  end loop;

  declare
    d  text not null := '';
    ds constant text[] :=
      (
        select array_agg(datname)
        from pg_database
        where datname = any(dbs_for_deletion)
      );
  begin
    if not (ds is null or cardinality(ds) < 1) then
      z :=          $$  \c yugabyte clstr$mgr                                               $$;     return next;
      foreach d in array ds loop
        z := format($$  alter database %I with allow_connections false connection limit 0;  $$, d); return next;
      end loop;

      foreach d in array ds loop
        z := format($$  call mgr.kill_all_sessions_for_specified_database(%L);              $$, d); return next;
        z := format($$  drop database %I;                                                   $$, d); return next;
      end loop;
    end if;

    -- Have this script remove itself when it has been executed.
    -- "rm -Rf" suppresses error messages when nothing to delete.
    z := format('\! rm -Rf %s', filename);                                                          return next;
  end;
end;
$body$;

revoke all on function mgr.drop_tenant_databases_script(text, int, int) from public;
