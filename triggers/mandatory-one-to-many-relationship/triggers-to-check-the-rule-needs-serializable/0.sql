\c d5 d5$mgr
call mgr.drop_all_regular_tenant_roles();
call mgr.comment_on_current_db(
  '"Enforcing the mandatory 1:M rule with a trigger that counts the number '||e'\n'||
  'of children and that relies on using the "serializable" isolation level. ');

call mgr.cr_role('data', with_temp_on_db=>true,  comment=>'Owns all the tables and associated objects that implement this case study');
call mgr.cr_role('code', with_temp_on_db=>false, comment=>'Owns all the code that accesses the tables that "data" owns');

call mgr.set_role_path('client', 'code, mgr, pg_catalog, pg_temp');

\ir 20-cr-tables.sql
\ir 30-cr-triggers.sql
\ir 40-cr-code.sql
\ir 50-populate-test-data.sql
\ir 60-do-single-session-tests.sql

/*
  THIS TEST MUST BE DONE MANUALLY TO CO-ORDINATE INTERLEAVING STEPS
  IN TWO CONURRENT SESSIONS

  70-do-two-session-tests.sql
*/;
