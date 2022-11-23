\c d1 d1$mgr
call mgr.drop_all_regular_tenant_roles();
call mgr.comment_on_current_db(
  'Case study:'||e'\n'||
  'Demonstrating the non-lossy mutual xform between a conventional relational representation'||e'\n'||
  'and a JSON representation of facts about books and their authors.');

call mgr.cr_role('json', comment=>'Owns all the objects that implement this case study');
set role d1$json;
set search_path = json, mgr, pg_catalog, pg_temp;
----------------------------------------------------------------------------------------------------

\pset null ''
\t off
\ir 01-cr-types.sql
\ir 02-cr-no_null_keys.sql
\ir 03-cr-j-books-table.sql
\ir 04-cr-j-books_keys.sql
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
