\c d1 d1$mgr
call mgr.cr_role('json', with_temp_on_db=>true, comment=>
  'Owns all the objects that demonstrate the non-lossy mutual xform '||e'\n'||
  'between a conventional relational representation and a JSON representation '||e'\n'||
  'of facts about books and their authors. ');
call mgr.set_role('json');
----------------------------------------------------------------------------------------------------

\pset null ''
\t off

\ir 01-cr-types.sql
\ir 02-cr-no-null-keys.sql
\ir 03-cr-j-books-table.sql
\ir 04-cr-j-books-keys.sql
\ir 05-populate-j-books-table.sql
\ir 06-alter-j-books-add-indexes-and-constraints.sql
\ir 08-query-the-j-books-table.sql
\ir 09-cr-j-books-r-view-and-populate-r-books.sql
\ir 10-cr-r-books-j-view.sql
\ir 11-assert-j-books-r-books-j-view-identical.sql

/*
  Do each statement by hand, one-by-one, from:
    07-do-manual-constraint-violation-tests.sql
*/;
