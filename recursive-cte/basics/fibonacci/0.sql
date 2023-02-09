\c d1 d1$mgr
call mgr.cr_role('cte_basics_fib', comment=>'Owns all the objects for the "recursive-cte/basics/fibonacci" case study.');
call mgr.set_role('cte_basics_fib');

\t off
\ir 1-fibonacci-cte.sql
\ir 2-fibonacci-plpgsql.sql
