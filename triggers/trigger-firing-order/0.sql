\c d3 d3$mgr
call mgr.drop_all_regular_tenant_roles();
call mgr.comment_on_current_db('"Trigger Firing Order" case study.');

call mgr.cr_role('u1');
set role d3$u1;

\ir 1-cr-tracing-helpers.sql
\ir 2-cr-tables.sql
\ir 3-cr-trigger-function.sql
\ir 4-cr-triggers.sql
\ir 5-cr-code.sql
\ir 6-do-tests.sql
\ir 7-internal-triggers.sql
