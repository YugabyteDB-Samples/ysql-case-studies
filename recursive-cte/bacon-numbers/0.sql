\c d1 d1$mgr

call mgr.cr_role('bacon', comment=>
  'Owns all the objects that implement the recursive CTE "Bacon numbers" case study '||e'\n'||
  'using: (1) synthetic data, and (2) a curated subset of the real IMDb. ');
call mgr.prepend_to_current_search_path('bacon');
call mgr.set_role('bacon');
\t off

-------------------------------------------------------
-- Synthetic Data
-------------------------------------------------------
\ir 01-cr-tables.sql
\ir 02-cr-edges-table-and-proc.sql
\ir 03-insert-synthetic-data-and-compute-edges.sql
\ir 04-check-edges-table-contents.sql
\ir 05-cr-raw-paths-table.sql
\ir 06-cr-list-paths.sql
\ir 07-find-paths-naive.sql
call find_paths(start_node => 'Emily');
\ir 08-list-paths-naive.sql
\ir 09-cr-raw-paths-with-tracing.sql
\ir 10-find-paths-no-pruning.sql
call find_paths('Emily', false);
\ir 11-list-paths-no-pruning.sql
\ir 12-cr-restrict-to-unq_containing-paths.sql
\ir 13-find-paths-with-pruning.sql
\ir 14-cr-decorated-paths-report.sql

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
