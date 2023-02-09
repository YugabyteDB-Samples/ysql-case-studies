\c d1 d1$mgr
call mgr.cr_role('trg_firing_order', comment=>'Owns all the objects for the "Trigger Firing Order" case study.');
call mgr.set_role('trg_firing_order');

\ir 1-cr-tracing-helpers.sql
\ir 2-cr-tables.sql
\ir 3-cr-trigger-function.sql
\ir 4-cr-triggers.sql
\ir 5-cr-code.sql
\ir 6-do-tests.sql
\ir 7-internal-triggers.sql
