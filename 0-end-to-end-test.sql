-- Establish a known starting state: a pristine YBMT cluster
\ir ybmt-clstr-mgmt/01-re-initialize-ybmt-clstr.sql

select extract(epoch from clock_timestamp())::text as overall_start \gset stopwatch_

--------------------------------------------------------------------------------
/*
  Can't spool the timing output here because the script itself uses "\o" t
  write the script that it will then run.
*/;
\set lower_db_no 0
\set upper_db_no 3
select extract(epoch from clock_timestamp())::text as s0
\gset stopwatch_
\ir ybmt-clstr-mgmt/02-drop-and-re-create-tenant-databases.sql
select ''''||stopwatch_reading(:stopwatch_s0)||'''' as initial_cr_6_tenant_dbs
\gset stopwatch_

--------------------------------------------------------------------------------
/*
  Can't spool the timing output here because the script itself uses "\o" t
  write the script that it will then run.
*/;
select extract(epoch from clock_timestamp())::text as s0
\gset stopwatch_
\ir ybmt-clstr-mgmt/02-drop-and-re-create-tenant-databases.sql

\c d0 d0$mgr
call mgr.comment_on_current_db('Database for ad hoc, throw-away tests. ');

\c d1 d1$mgr
call mgr.comment_on_current_db('Miscellaneous single-schema case studies. ');

select ''''||stopwatch_reading(:stopwatch_s0)||'''' as drop_and_re_cr_6_tenant_dbs
\gset stopwatch_

--------------------------------------------------------------------------------
/*
  Can't spool the timing output here because the script itself uses "\o" t
  write the script that it will then run.
*/;

select extract(epoch from clock_timestamp())::text as s0
\gset stopwatch_
\ir analyzing-covid-data-with-aggregate-functions/1-set-up-and-ingest-the-covid-data.sql

--------------------------------------------------------------------------------
-- Start spooling here.
select (version() like '%YB%')::text as is_yb
\gset

\if :is_yb
  \o output/yb.txt
\else
  \o output/pg.txt
\endif

\t on
select rule_off('Create 6 tenant databases');
select :stopwatch_initial_cr_6_tenant_dbs;

select rule_off('Drop and re-create those 6 tenant databases');
select :stopwatch_drop_and_re_cr_6_tenant_dbs;

--------------------------------------------------------------------------------
\c d1 d1$mgr
\t on \\ select rule_off('analyzing-covid-data-with-aggregate-functions');
call mgr.prepend_to_current_search_path('covid');
call mgr.set_role('covid');
\ir analyzing-covid-data-with-aggregate-functions/0.sql
\t on \\ select 'analyzing-covid-data-with-aggregate-functions: '||stopwatch_reading(:stopwatch_s0);

--------------------------------------------------------------------------------
\c d1 d1$mgr
\t on \\ select rule_off('recursive-cte/basics/procedural-implementation-of-recursive-cte-algorithm');
select extract(epoch from clock_timestamp())::text as s0
\gset stopwatch_
\ir recursive-cte/basics/procedural-implementation-of-recursive-cte-algorithm/0.sql
\t on \\ select 'recursive-cte/basics/procedural-implementation-of-recursive-cte-algorithm: '||stopwatch_reading(:stopwatch_s0);

--------------------------------------------------------------------------------
\c d1 d1$mgr
\t on \\ select rule_off('recursive-cte/basics/fibonacci');
select extract(epoch from clock_timestamp())::text as s0
\gset stopwatch_
\ir recursive-cte/basics/fibonacci/0.sql
\t on \\ select 'recursive-cte/basics/fibonacci: '||stopwatch_reading(:stopwatch_s0);

--------------------------------------------------------------------------------
\c d1 d1$mgr
\t on \\ select rule_off('recursive-cte/employee-hierarchy');
select extract(epoch from clock_timestamp())::text as s0
\gset stopwatch_
\ir recursive-cte/employee-hierarchy/0.sql
\t on \\ select 'recursive-cte/employee-hierarchy: '||stopwatch_reading(:stopwatch_s0);

--------------------------------------------------------------------------------
\c d1 d1$mgr
\t on \\ select rule_off('recursive-cte/bacon-numbers');
select extract(epoch from clock_timestamp())::text as s0
\gset stopwatch_
\ir recursive-cte/bacon-numbers/0.sql
\t on \\ select 'recursive-cte/bacon-numbers: '||stopwatch_reading(:stopwatch_s0);

--------------------------------------------------------------------------------
\c d2 d2$mgr
\t on \\ select rule_off('date-time-utilities');
select extract(epoch from clock_timestamp())::text as s0
\gset stopwatch_
\ir date-time-utilities/0.sql
\t on \\ select 'date-time-utilities: '||stopwatch_reading(:stopwatch_s0);

--------------------------------------------------------------------------------
\c d1 d1$mgr
\t on \\ select rule_off('json-relational-equivalence');
select extract(epoch from clock_timestamp())::text as s0
\gset stopwatch_
\ir json-relational-equivalence/0.sql
\t on \\ select 'json-relational-equivalence: '||stopwatch_reading(:stopwatch_s0);

--------------------------------------------------------------------------------
\c d3 d3$mgr
\t on \\ select rule_off('hard-shell');
select extract(epoch from clock_timestamp())::text as s0
\gset stopwatch_
\ir hard-shell/0.sql
\t on \\ select 'hard-shell: '||stopwatch_reading(:stopwatch_s0);

--------------------------------------------------------------------------------
\c d1 d1$mgr
\t on \\ select rule_off('triggers/trigger-firing-order');
select extract(epoch from clock_timestamp())::text as s0
\gset stopwatch_
\ir triggers/trigger-firing-order/0.sql
\t on \\ select 'triggers/trigger-firing-order: '||stopwatch_reading(:stopwatch_s0);

--------------------------------------------------------------------------------
\c d1 d1$mgr
\t on
select rule_off('Tenant databases and tenant roles in tenant database "d1"');

select rule_off('Tenant databases', 'level_3');
select z from mgr.dbs_with_comments(exclude_system_dbs=>true);

select rule_off('Tenant roles in tenant database "d1"', 'level_3');
select z from mgr.roles_with_comments(exclude_mgr_developer_client_and_global_roles=>true);

--------------------------------------------------------------------------------
\c yugabyte yugabyte
\t on
select rule_off('End-to-end time');

call mgr.assert_no_db_has_privs_granted_to_public();
select stopwatch_reading(:stopwatch_overall_start);
\t off
\o
