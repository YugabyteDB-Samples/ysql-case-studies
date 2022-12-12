\c d2 d2$mgr
call mgr.drop_all_regular_tenant_roles();
call mgr.comment_on_current_db('"Date-time datatypes" case study. ');

call mgr.cr_role('ext_tz_names', comment=>'Owns the "extended_timezone_names" view and its cousins.');
set role d2$ext_tz_names;
grant usage on schema ext_tz_names to public;

\ir 1-cr-date-time-utility-objects/1-cr-extended-timezone-names-views/0.sql
\ir 1-cr-date-time-utility-objects/2-cr-encapsulations-for-set-timezone-and-at-timezone/0.sql
\ir 1-cr-date-time-utility-objects/3-cr-functions-for-legal-scopes-for-syntax-context/0.sql

reset role;
call mgr.cr_role('date_time_tests', comment=>'Owns all the objects for testing the "date-time-utilities".');
call mgr.prepend_to_session_path('ext_tz_names');
call mgr.prepend_to_session_path('date_time_tests');
set role d2$date_time_tests;

\ir 2-do-tests/1-test-internal-interval-representation-model/0.sql
\ir 2-do-tests/2-test-interval-domains/do-tests.sql
\ir 2-do-tests/3-test-extended-timezone-names-views/extended-timezone-names-to-plain-text/0.sql

/*
  This was used to create the .md tables in the YSQL doc.
  But running it here adds no testing value w.r.t. running "extended-timezone-names-to-plain-text/0.sql"
  \ir 2-do-tests/3-test-extended-timezone-names-views/extended-timezone-names-to-md-table/0.sql
*/;

\ir 2-do-tests/4-test-encapsulations-for-set-timezone-and-at-timezone/0.sql
\ir 2-do-tests/5-test-functions-for-legal-scopes-for-syntax-context/0.sql
