/*
  This is first created with owner "yugabyte". Then, after its first use, it's
  re-created with owner "clstr$mgr". It can't be created with this owner at the start
  because this role won't yet exist when "../01-re-initialize-ybmt-clstr.sql" is first run.
  However, "clstr$mgr" cannot be created before the present script is run because when it
  does exist, it will be dropped and re-created. But it's too tedious to connect to every
  extant tenant database in turn, using a generated script, to to "drop owned by" so
  that "drop role" won't cause an error. Hence the seq  uencing challenge. The least
  bad approach was therefore adopted.
*/;

/*
  www.postgresql.org/docs/11/monitoring-stats.html#PG-STAT-ACTIVITY-VIEW
  From the PG doc: "only superusers can terminate superuser backends."

  This is reliable only on single-node YB (and on PG, of course).

  See https://github.com/yugabyte/yugabyte-db/issues/14217
  For a hint for how to write a Python script to visit each YB cluster node
  in turn and kill the PG backend proceses that are running there.

  Using the default NULL means kill ALL other sessions but self.
*/;
create procedure mgr.kill_all_sessions_for_specified_database(db_name in name default null)
  security definer
  set client_min_messages = warning
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  p int not null := 0;

  pids constant int[] :=
    case
      when db_name is null then
        (
          select array_agg(pid)
          from pg_stat_activity
          where backend_type = 'client backend'
          and   pid <> pg_backend_pid()
        )
      else
        (
          select array_agg(pid)
          from pg_stat_activity
          where backend_type = 'client backend'
          and datname        = db_name
        )
    end;
begin
  if db_name is not null then
    begin
      execute format('alter database %I with connection limit 0', db_name);
    exception when invalid_catalog_name then null; end;
  end if;

  if (pids is not null and cardinality(pids) > 0) then
    foreach p in array pids loop
      perform pg_terminate_backend(p);
    end loop;
  end if;
end;
$body$;

revoke all on procedure mgr.kill_all_sessions_for_specified_database(name) from public;
