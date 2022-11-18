\ir 03-insert-synthetic-data-and-compute-edges.sql
call find_paths('Emily', false);

delete from temp_paths;
insert into temp_paths(path)
select path from raw_paths where cardinality(path) = 4;
delete from raw_paths where cardinality(path) >= 4;

-- Tidy up to get where we'd be at this point WITH pruning
-- Prune all but one path to each distinct new terminal.
delete from raw_paths
where
(
  path not in (select min(path) from raw_paths group by terminal(path)) and
  terminal(path) in (select terminal(path) from raw_paths)
);

\t on

select rule_off('Pruning demo', 'level_3');

select '"raw_paths" to date after one rep. of the recursive term.';
select path from raw_paths order by path[1], path[2], path[3], path[4];

select '"temp_paths" produced by the second rep. of the recursive term before pruning.';
select path from temp_paths order by path[1], path[2], path[3], path[4];

-- Prune all but one path to each distinct new terminal.
delete from temp_paths
where
(
  path not in (select min(path) from temp_paths group by terminal(path))
);

select '"temp_paths" after pruning all but one path to each distinct new terminal.';
select path from temp_paths order by path[1], path[2], path[3], path[4];

-- Prune newer (and therefore longer) paths to
-- already-found terminals.
delete from temp_paths
where
(
  terminal(path) in
  (
    select terminal(path)
    from raw_paths
  )
);

select '"temp_paths" after pruning newer (and therefore longer) paths to already-found terminals.';
select path from temp_paths order by path[1], path[2], path[3], path[4];
select 'Nothing survives. So the (so-called) recursion stops.';
\t off
