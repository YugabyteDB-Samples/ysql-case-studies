\ir 03-insert-synthetic-data-and-compute-edges.sql
drop index if exists bacon.raw_paths_terminal_unq cascade;
call bacon.find_paths('Emily', false);

delete from bacon.temp_paths;
insert into bacon.temp_paths(path)
select path from bacon.raw_paths where cardinality(path) = 4;
delete from bacon.raw_paths where cardinality(path) >= 4;

-- Tidy up to get where we'd be at this point WITH pruning
-- Prune all but one path to each distinct new terminal.
delete from bacon.raw_paths
where
(
  path not in (select min(path) from bacon.raw_paths group by bacon.terminal(path)) and
  bacon.terminal(path) in (select bacon.terminal(path) from bacon.raw_paths)
);

\t on

select client_safe.rule_off('Pruning demo', 'level_3');

select '"raw_paths" to date after one rep. of the recursive term.';
select path from bacon.raw_paths order by path[1], path[2], path[3], path[4];

select '"temp_paths" produced by the second rep. of the recursive term before pruning.';
select path from bacon.temp_paths order by path[1], path[2], path[3], path[4];

-- Prune all but one path to each distinct new terminal.
delete from bacon.temp_paths
where
(
  path not in (select min(path) from bacon.temp_paths group by bacon.terminal(path))
);

select '"temp_paths" after pruning all but one path to each distinct new terminal.';
select path from bacon.temp_paths order by path[1], path[2], path[3], path[4];

-- Prune newer (and therefore longer) paths to
-- already-found terminals.
delete from bacon.temp_paths
where
(
  bacon.terminal(path) in
  (
    select bacon.terminal(path)
    from bacon.raw_paths
  )
);

select '"temp_paths" after pruning newer (and therefore longer) paths to already-found terminals.';
select path from bacon.temp_paths order by path[1], path[2], path[3], path[4];
select 'Nothing survives. So the (so-called) recursion stops.';
\t off
