/*
  This is first created with owner "postgres". Then, after its first use, it's
  re-created with owner "clstr$mgr". See the comment in
  "01-kill-all-sessions-for-specified-database.sql".
*/;
create procedure mgr.drop_all_non_system_roles()
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
   r text;
begin
  assert current_database() = 'postgres',
    'current_database() is not "postgres"';

  assert current_role  = 'postgres',
    'current_role is not "postgres"';

  for r in (
      select rolname::text
      from pg_roles
      where rolname != 'postgres'
      and   rolname != 'clstr$mgr'
      and   rolname !~ '^pg_'
      and   rolname !~ '^yb_'
    )
  loop
    execute format('drop owned by %I cascade;', r);
    execute format('drop role %I;', r);
  end loop;
end;

$body$;

revoke all on procedure mgr.drop_all_non_system_roles() from public;
