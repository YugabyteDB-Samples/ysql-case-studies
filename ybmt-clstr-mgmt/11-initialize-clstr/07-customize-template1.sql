/*
  Customize the "template1" database. See "22.3. Template Databases":

    www.postgresql.org/docs/11/manage-ag-templatedbs.html

  Establish "template1" as the definition of the so-called "tenant database"
  for the present "home-grown" multitenancy env.
*/;

alter database template1 with allow_connections true connection limit 2;
--------------------------------------------------------------------------------

\c template1 yugabyte
set client_min_messages = 'warning';

grant create on database template1 to clstr$mgr with grant option;

-- For utilities deemed to be safe for "client" use.
create schema client_safe authorization clstr$mgr;
grant usage on schema client_safe to public;

-- For misc. generic utilities.
create schema mgr authorization clstr$mgr;

-- For the date-time utilities
create schema dt_utils authorization clstr$mgr;

-- Make e.g. extensions.gen_random_uuid() and extensions.normal_rand() available.
create schema extensions authorization clstr$mgr;
create extension pgcrypto  with schema extensions;
create extension tablefunc with schema extensions;

/*
  These grants to "public" will be revoked by
    06-xfer-schema-grants-from-public-to-clstr-developer.sql
  They are done here so that you can experiment by commenting out
  the invocation of that script (below). Everything still works.
  And the total time for "0-end-to-end-test.sql" is quicker.
*/;
grant usage on schema mgr        to public;
grant usage on schema dt_utils   to public;
grant usage on schema extensions to public;

\ir ../12-schema-objects-for-template1/08-cr-set-tenant-database-setting.sql
grant execute on procedure mgr.set_tenant_database_setting(text, text, text) to clstr$mgr;

\ir ../12-schema-objects-for-template1/14-cr-drop-all-temp-schemas.sql
grant execute on procedure mgr.drop_all_temp_schemas() to clstr$mgr with grant option;

/*
  Experiment by commenting this out.
  Will need to re-create the cluster after commenting IN or OUT.

  When commented out, move "pg.txt" to
    "xfer-schema-grants-from-public-to-clstr-developer-choices/pg-everything-public.txt

  Else see the comment "Experiment by commenting this block out."
  in "06-xfer-schema-grants-from-public-to-clstr-developer.sql".
*/;
\ir 06-xfer-schema-grants-from-public-to-clstr-developer.sql

set role clstr$mgr;

\ir ../12-schema-objects-for-template1/01-cr-where-am-i.sql
\ir ../12-schema-objects-for-template1/02-cr-random-script-filename.sql
\ir ../12-schema-objects-for-template1/03-cr-ybmt-utility-views-and-functions.sql
\ir ../12-schema-objects-for-template1/04-cr-rule-off.sql
\ir ../12-schema-objects-for-template1/05-cr-stopwatch.sql
\ir ../12-schema-objects-for-template1/06-cr-dbms-output-simulation.sql
\ir ../12-schema-objects-for-template1/07-cr-catalog-views-and-table-functions.sql
\ir ../12-schema-objects-for-template1/09-cr-tenant-role-mgmt-procs.sql
\ir ../12-schema-objects-for-template1/10-cr-set-up-tenant-database.sql
\ir ../12-schema-objects-for-template1/11-cr-proper-and-improper-ybmt-roles-views.sql
\ir ../12-schema-objects-for-template1/12-cr-assert-expected-schemas.sql
\ir ../12-schema-objects-for-template1/13-cr-assert-no-db-has-privs-granted-to-public.sql

\ir ../12-schema-objects-for-template1/date-time-utilities/1-interval-utilities/0.sql
\ir ../12-schema-objects-for-template1/date-time-utilities/2-interval-domains/0.sql
--------------------------------------------------------------------------------

\c yugabyte yugabyte
set client_min_messages = 'warning';

alter database template1 with allow_connections false connection limit 0;
revoke all on database template1 from clstr$mgr;
