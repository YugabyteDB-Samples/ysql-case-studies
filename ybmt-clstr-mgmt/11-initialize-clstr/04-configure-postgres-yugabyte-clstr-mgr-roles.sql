/*
  YB limitation: setting "connection :limit 0" causes this error:
    42601: cannot set connection limit for postgres
  Has no ultimate practical significance.
*/;

alter role postgres with
  superuser
  nocreaterole
  nocreatedb
  noreplication
  nobypassrls
  connection limit -1
  login password null;

-- Just in case an intervention needs "posgres" to be allowed to start sessions 
alter role postgres set search_path = dt_utils, mgr, extensions, pg_catalog, pg_temp;
--------------------------------------------------------------------------------

alter role yugabyte with
  superuser
  nocreaterole
  nocreatedb
  noreplication
  nobypassrls
  connection limit 0
  login password 'x';

alter role yugabyte set search_path = dt_utils, mgr, extensions, pg_catalog, pg_temp;
--------------------------------------------------------------------------------

alter role clstr$mgr with
  nosuperuser
  createrole
  createdb
  noreplication
  nobypassrls
  connection limit -1
  login password 'x';

grant connect on database yugabyte to clstr$mgr;
grant create  on database yugabyte to clstr$mgr;
alter role clstr$mgr set search_path = dt_utils, mgr, extensions, pg_catalog, pg_temp;
