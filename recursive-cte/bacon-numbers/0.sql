\c d1 d1$mgr

call mgr.cr_role('bacon', with_temp_on_db=>true, comment=>
  'Owns all the objects that implement the recursive CTE "Bacon numbers" case study '||e'\n'||
  'using: (1) synthetic data, and (2) a curated subset of the real IMDb. ');
call mgr.set_role('bacon');
\t off

-------------------------------------------------------
-- Synthetic Data
-------------------------------------------------------
-- Force the use of qualified idenitifiers
set search_path = pg_catalog, pg_temp;

\ir 01-cr-tables.sql
\ir 02-cr-edges-table-and-proc.sql
\ir 03-insert-synthetic-data-and-compute-edges.sql
\ir 04-check-edges-table-contents.sql
\ir 05-cr-raw-paths-table.sql
\ir 06-cr-list-paths.sql
\ir 07-cr-find-paths-naive.sql

drop index if exists bacon.raw_paths_terminal_unq cascade;
call bacon.find_paths(start_node => 'Emily');

\ir 08-list-paths-naive.sql
\ir 09-cr-raw-paths-with-tracing.sql
\ir 10-cr-find-paths-with-pruning.sql

drop index if exists bacon.raw_paths_terminal_unq cascade;
call bacon.find_paths('Emily', false);

\ir 11-list-paths-no-pruning.sql
\ir 12-cr-restrict-to-unq-containing-paths.sql

call bacon.create_path_table('unq_containing_paths', false);
call bacon.restrict_to_unq_containing_paths('raw_paths', 'unq_containing_paths');

\t on
select t from bacon.list_paths('unq_containing_paths');
\t off

\ir 13-find-paths-with-pruning.sql
\ir 14-cr-decorated-paths-report.sql

\t on
select t from bacon.decorated_paths_report('raw_paths');
select t from bacon.decorated_paths_report('raw_paths', 'Helen');
\t off

-------------------------------------------------------
-- Real IMDB data
-------------------------------------------------------
\ir 15-insert-imdb-data.sql
\ir 16-inspect-imdb-data.sql
\ir 17-find-imdb-paths.sql

-------------------------------------------------------
-- Pruning demo
-------------------------------------------------------
\ir 99-pruning-demo.sql
