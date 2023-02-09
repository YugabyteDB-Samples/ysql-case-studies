-- THE CURATED IMDB SUBSET FROM OBERLIN WAS CHOSEN SO THAT EVERY
-- ACTOR IS CONNECTED TO KEVIN BACON.

\t on
select '------------------------------------------------------------';
select 'Seed: Kevin Bacon';
drop index if exists bacon.raw_paths_terminal_unq cascade;
call bacon.find_paths('Kevin Bacon (I)', true);
create unique index raw_paths_terminal_unq on bacon.raw_paths(bacon.terminal(path));

select 'total number of pruned paths:            '||count(*)::text from bacon.raw_paths;

select 'Max path length:                         '||max(cardinality(path)) from bacon.raw_paths;

select 'unreached:                               '||actor
from bacon.actors
where actor not in (
  select bacon.terminal(path) from bacon.raw_paths)
order by actor;

select 'Maximum distance match:                  '||bacon.terminal(path)
from bacon.raw_paths
where cardinality(path) = (
  select max(cardinality(path)) from bacon.raw_paths);

call bacon.create_path_table('unq_containing_paths', false);
call bacon.restrict_to_unq_containing_paths('raw_paths', 'unq_containing_paths');
select 'total number of unique containing paths: '||count(*)::text from bacon.unq_containing_paths;

select t from bacon.decorated_paths_report('raw_paths', 'Christopher Nolan');

select '------------------------------------------------------------';
select 'Seed: Christopher Nolan';
drop index if exists bacon.raw_paths_terminal_unq cascade;
call bacon.find_paths('Christopher Nolan', true);
create unique index raw_paths_terminal_unq on bacon.raw_paths(bacon.terminal(path));

select 'total number of pruned paths:            '||count(*)::text from bacon.raw_paths;

select 'Max path length:                         '||max(cardinality(path)) from bacon.raw_paths;

select 'unreached:                               '||actor
from bacon.actors
where actor not in (
  select bacon.terminal(path) from bacon.raw_paths)
order by actor;

select t from bacon.decorated_paths_report('raw_paths', 'Kevin Bacon (I)');

\t off
