/*
  YB limitation: setting "connection :limit 0" causes this error:
    42601: cannot set connection limit for postgres
  Has no ultimate practical significance.
*/;

alter role postgres with
  superuser
  nocreaterole
  nocreatedb
  noinherit
  noreplication
  nobypassrls
  connection limit -1
  login password null;

-- Just in case an intervention needs "posgres" to be allowed to start sessions 
alter role postgres set search_path = pg_catalog, client_safe, dt_utils, mgr, extensions, pg_temp;
--------------------------------------------------------------------------------

alter role yugabyte with
  superuser
  nocreaterole
  nocreatedb
  noinherit
  noreplication
  nobypassrls
  connection limit 0
  login password 'x';

alter role yugabyte set search_path = pg_catalog, client_safe, dt_utils, mgr, extensions, pg_temp;
--------------------------------------------------------------------------------

alter role clstr$mgr with
  nosuperuser
  createrole
  createdb
  inherit
  noreplication
  nobypassrls
  connection limit -1
  login password 'x';

/*
  See "21.5. Default Roles" in the PG doc on "pg_read_all_stats"
  https://www.postgresql.org/docs/11/default-roles.html

  pg_read_all_stats « Read all pg_stat_* views and use various statistics related extensions,
                      even those normally visible only to superusers. »

  pg_signal_backend « Signal another backend to cancel a query or terminate its session. »

  Do the following test while several other concurrent sessions, authorized with various different roles, exist.

  The "pg_stat_activity" query sees "backend_type is NULL: for sessions other than self
  unless "clstr$mgr" has "pg_read_all_stats".  With the grant, it sees "client backend".

  \c d0 yugabyte
  revoke pg_read_all_stats from clstr$mgr;
  \c d0 clstr$mgr
  select datname, usename, backend_type, pid from pg_stat_activity order by pid;

  \c d0 yugabyte
  grant pg_read_all_stats to clstr$mgr;
  \c d0 clstr$mgr
  select datname, usename, backend_type, pid from pg_stat_activity order by pid;

  Needed for these procedures:
    mgr.kill_all_sessions_for_role()
    mgr.kill_all_sessions_for_specified_database()
*/
grant pg_read_all_stats to clstr$mgr;
grant pg_signal_backend to clstr$mgr;

-- Will revoke these privileges as soon as they're no longer needed.
grant connect on database yugabyte to clstr$mgr;
grant create  on database yugabyte to clstr$mgr;
alter role clstr$mgr set search_path = pg_catalog, client_safe, dt_utils, mgr, extensions, pg_temp;
--------------------------------------------------------------------------------

alter role clstr$developer with
  nosuperuser
  nocreaterole
  nocreatedb
  noinherit
  noreplication
  nobypassrls
  connection limit 0
  nologin password null;
