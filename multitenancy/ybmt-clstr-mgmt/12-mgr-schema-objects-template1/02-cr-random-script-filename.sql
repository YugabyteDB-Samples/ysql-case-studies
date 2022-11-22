/*
  This is first created with owner "postgres". Then, after its first use, it's
  re-created with owner "clstr$mgr". See the comment in
  "../13-mgr-schema-objects-postgres-db-only/01-kill-all-sessions-for-specified-database.sql".
*/;

create function mgr.random_script_filename()
  returns text
  security definer
  set search_path = pg_catalog, pg_temp
  language sql
as $body$
  select
    '/etc/ybmt-generated/sql-scripts/'||
    ltrim(to_char(floor(random()*999999999995.0), '000000000009'))||'.sql';
$body$;

revoke all on function mgr.random_script_filename() from public;
