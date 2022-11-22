/*
  YB limitation: setting "connection :limit 0" causes this error:

    42601: cannot set connection limit for postgres

  Has no ultimate practical significance.
*/;

-- Set password to NULL presently.
alter role postgres with
  superuser
  nocreaterole
  nocreatedb
  noreplication
  nobypassrls
  connection limit -1
  login password 'x';

alter role postgres set search_path = mgr, pg_catalog, pg_temp;
set search_path = mgr, pg_catalog, pg_temp;
