\c d1 d1$mgr
call mgr.cr_role('employees', comment=>'Owns all the objects for the "recursive-cte/employee-hierarchy" case study.');
call mgr.set_role('employees');

\t off
\ir 1-cr-table.sql
\ir 2-bare-recursive-cte.sql
\ir 3-top-down-paths.sql
\ir 4-bottom-up-path.sql
