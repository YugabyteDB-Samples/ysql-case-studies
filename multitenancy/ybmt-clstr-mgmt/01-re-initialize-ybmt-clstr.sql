\set VERBOSITY verbose
\set ON_ERROR_STOP true
\t off
\x off
--------------------------------------------------------------------------------
\c postgres postgres
set client_min_messages = 'warning';

\ir 11-initialize-clstr/01-initialize-postgres-and-template1-databases.sql
\ir 11-initialize-clstr/02-lock-down-postgres-role.sql
\ir 13-mgr-schema-objects-postgres-db-only/01-kill-all-sessions-for-specified-database.sql
\ir 13-mgr-schema-objects-postgres-db-only/02-cr-drop-all-non-system-databases-script.sql
\ir 13-mgr-schema-objects-postgres-db-only/03-cr-drop-all-non-system-roles.sql

\ir 12-mgr-schema-objects-template1/02-cr-random-script-filename.sql
\ir 11-initialize-clstr/03-drop-all-non-system-databases.sql
call mgr.drop_all_non_system_roles();
\ir 11-initialize-clstr/04-cr-clstr-mgr-role.sql

drop schema mgr cascade;
set role clstr$mgr;
create schema mgr authorization clstr$mgr;

\ir 12-mgr-schema-objects-template1/01-cr-where-am-i.sql
\ir 12-mgr-schema-objects-template1/02-cr-random-script-filename.sql
\ir 12-mgr-schema-objects-template1/03-cr-ybmt-utility-views-and-functions.sql
\ir 12-mgr-schema-objects-template1/04-cr-generic-utils.sql
\ir 12-mgr-schema-objects-template1/05-cr-catalog-views-and-table-functions.sql
\ir 12-mgr-schema-objects-template1/09-cr-proper-and-improper-ybmt-roles-views.sql

\ir 13-mgr-schema-objects-postgres-db-only/01-kill-all-sessions-for-specified-database.sql
\ir 13-mgr-schema-objects-postgres-db-only/02-cr-drop-all-non-system-databases-script.sql
\ir 13-mgr-schema-objects-postgres-db-only/03-cr-drop-all-non-system-roles.sql
\ir 13-mgr-schema-objects-postgres-db-only/04-cr-drop-tenant-databases-script.sql
\ir 13-mgr-schema-objects-postgres-db-only/05-cr-create-tenant-databases-script.sql
\ir 13-mgr-schema-objects-postgres-db-only/06-cr_drop-all-improper-ymbt_roles.sql
\ir 13-mgr-schema-objects-postgres-db-only/07-cr-assert-re-initialized-clstr-ok.sql

reset role;
revoke create on schema mgr from clstr$mgr;

\ir 11-initialize-clstr/05-customize-template1.sql
\ir 11-initialize-clstr/06-harden-all-databases.sql
\ir 11-initialize-clstr/07-comment-on-initial-roles-and-dbs.sql

call mgr.assert_re_initialized_clstr_ok();

\set VERBOSITY default
\set ON_ERROR_STOP false
