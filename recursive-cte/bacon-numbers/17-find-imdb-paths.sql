-- THE CURATED IMDB SUBSET FROM OBERLIN WAS CHOSEN SO THAT EVERY
-- ACTOR IS CONNECTED TO KEVIN BACON.

\t on
select '------------------------------------------------------------';
select 'Seed: Kevin Bacon';
call find_paths('Kevin Bacon (I)', true);

select 'total number of pruned paths:            '||count(*)::text from raw_paths;

select 'Max path length:                         '||max(cardinality(path)) from raw_paths;

select 'unreached:                               '||actor
from actors
where actor not in (
  select terminal(path) from raw_paths)
order by actor;

select 'Maximum distance match:                  '||terminal(path)
from raw_paths
where cardinality(path) = (
  select max(cardinality(path)) from raw_paths);

call create_path_table('unq_containing_paths', false);
call restrict_to_unq_containing_paths('raw_paths', 'unq_containing_paths');
select 'total number of unique containing paths: '||count(*)::text from unq_containing_paths;

select t from decorated_paths_report('raw_paths', 'Christopher Nolan');

select '------------------------------------------------------------';
select 'Seed: Christopher Nolan';
call find_paths('Christopher Nolan', true);

select 'total number of pruned paths:            '||count(*)::text from raw_paths;

select 'Max path length:                         '||max(cardinality(path)) from raw_paths;

select 'unreached:                               '||actor
from actors
where actor not in (
  select terminal(path) from raw_paths)
order by actor;

select t from decorated_paths_report('raw_paths', 'Kevin Bacon (I)');

\t off
