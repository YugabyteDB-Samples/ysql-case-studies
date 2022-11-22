\pset null ''
\t off
\ir 01-create-caption.sql
\ir 02-examples-of-json-values-and-value-extraction.sql
\ir 03-typecasting-text-to-json(b)-to-text.sql
\ir 04-jsonb-null-semantics.sql
\ir 05-create-domains.sql
\ir 06-create-no_null_keys.sql
\ir 07-create-j-books-table.sql
\ir 08-create-j-books_keys.sql

/*
  The usual practice, when you create a table and then (bulk) populate it,
  while the application is being installed, is FIRST to populate the table
  and only THEN to create indexes and constraints. This script reverses
  that order. This is necessary to work around the effect of this YSQL issue:

  Internal error on creating a constraint that's based on a user-defined function
  github.com/yugabyte/yugabyte-db/issues/12875

  It actually has "Closed" status because it's a dup of this:

  github.com/yugabyte/yugabyte-db/issues/11487

  Therefore, please track Issue #11487. Only when it's fixed, can the order of
  scripts "09" and "10" be reversed.
*/;

\ir 09-alter-j-books-add-indexes-and-constraints.sql
\ir 10-populate-j-books-table.sql

\ir 12-query-the-j-books-table.sql
\ir 13-create-j-books-r-view-and-populate-r-books.sql
\ir 14-create-r-books-j-view.sql
\ir 15-assert-j-books-r-books-j-view-identical.sql

/*
  Do each statement by hand, one-ny-one, from:
  11-do-manual-constraint-violation-tests.sql
*/;
