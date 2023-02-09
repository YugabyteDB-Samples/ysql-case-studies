\c d1 d1$mgr
call mgr.cr_role('cte_basics_proc', comment=>'Owns all the objects for the "recursive-cte/basics/procedural-implementation-of-recursive-cte-algorithm" case study.');
call mgr.set_role('cte_basics_proc');

\t off
\ir 1-pure-sql.sql
\ir 2-cr-tables.sql
\ir 3-plpgsql-sql-hybrid.sql
