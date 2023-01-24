\set VERBOSITY verbose
\set ON_ERROR_STOP true
\t off
\x off
--------------------------------------------------------------------------------
\c yugabyte yugabyte
set client_min_messages = 'warning';

\ir 11-initialize-clstr/01-initialize-yugabyte-and-template1-databases.sql
\ir 13-schema-objects-for-yugabyte-db-only/01-cr-kill-all-sessions-for-specified-database.sql
\ir 13-schema-objects-for-yugabyte-db-only/02-cr-drop-all-non-system-databases-script.sql
\ir 12-schema-objects-for-template1/02-cr-random-script-filename.sql
\ir 11-initialize-clstr/02-drop-all-non-system-databases.sql

--Drop all non-system roles.
do $body$
declare
   r text;
begin
  for r in (
    select rolname::text
    from pg_roles
    where rolname != 'postgres'
    and   rolname != 'yugabyte'
    and   rolname !~ '^clstr\$'
    and   rolname !~ '^pg_'
    and   rolname !~ '^yb_')
  loop
    execute format('drop owned by %I cascade;', r);
    execute format('drop role %I;', r);
  end loop;
end;
$body$;

\ir 11-initialize-clstr/04-cr-clstr-mgr-and-clstr-developer-roles.sql
\ir 11-initialize-clstr/05-configure-postgres-yugabyte-clstr-mgr-roles.sql

drop schema mgr cascade;
set role clstr$mgr;
create schema mgr authorization clstr$mgr;
revoke all on schema mgr from public;

create schema client_safe authorization clstr$mgr;
revoke all on schema client_safe from public;

set role yugabyte;
\ir 12-schema-objects-for-template1/14-cr-drop-all-temp-schemas.sql
grant execute on procedure mgr.drop_all_temp_schemas() to clstr$mgr;
set role clstr$mgr;

\ir 12-schema-objects-for-template1/01-cr-where-am-i.sql
\ir 12-schema-objects-for-template1/02-cr-random-script-filename.sql
\ir 12-schema-objects-for-template1/03-cr-ybmt-utility-views-and-functions.sql
\ir 12-schema-objects-for-template1/04-cr-rule-off.sql
\ir 12-schema-objects-for-template1/05-cr-stopwatch.sql
\ir 12-schema-objects-for-template1/06-cr-dbms-output-simulation.sql
\ir 12-schema-objects-for-template1/07-cr-catalog-views-and-table-functions.sql
\ir 12-schema-objects-for-template1/11-cr-proper-and-improper-ybmt-roles-views.sql
\ir 12-schema-objects-for-template1/12-cr-assert-expected-schemas.sql
\ir 12-schema-objects-for-template1/13-cr-assert-no-db-has-privs-granted-to-public.sql

\ir 13-schema-objects-for-yugabyte-db-only/01-cr-kill-all-sessions-for-specified-database.sql
\ir 13-schema-objects-for-yugabyte-db-only/02-cr-drop-all-non-system-databases-script.sql
\ir 13-schema-objects-for-yugabyte-db-only/03-cr-drop-tenant-databases-script.sql
\ir 13-schema-objects-for-yugabyte-db-only/04-cr-create-tenant-databases-script.sql
\ir 13-schema-objects-for-yugabyte-db-only/05-cr_drop-all-improper-ymbt_roles.sql
\ir 13-schema-objects-for-yugabyte-db-only/06-cr-assert-re-initialized-clstr-ok.sql

call mgr.drop_all_temp_schemas();

set role yugabyte;
revoke create on schema mgr from clstr$mgr;
revoke all     on database yugabyte from clstr$mgr;
grant  connect on database yugabyte to   clstr$mgr;

\ir 11-initialize-clstr/07-customize-template1.sql
\ir 11-initialize-clstr/08-harden-all-databases.sql
\ir 11-initialize-clstr/09-comment-on-initial-roles-and-dbs.sql

call mgr.assert_expected_schemas();
alter database template1 with allow_connections true;
\c template1 yugabyte
call mgr.assert_expected_schemas();
\c yugabyte yugabyte
alter database template1 with allow_connections false;

call mgr.assert_re_initialized_clstr_ok();
call mgr.assert_no_db_has_privs_granted_to_public();

\set VERBOSITY default
\set ON_ERROR_STOP false
