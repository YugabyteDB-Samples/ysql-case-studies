create function bacon.terminal(path in text[])
  returns text
  immutable
  set search_path = pg_catalog, bacon, pg_temp
  language plpgsql
as $body$
begin
  return path[cardinality(path)];
end;
$body$;

create procedure bacon.find_paths(start_node in text)
  set search_path = pg_catalog, bacon, pg_temp
  language plpgsql
as $body$
begin
  -- See "cr-find-paths-with-pruning.sql". This index demonstrates that
  -- no more than one path has been found to any particular terminal node.
  drop index if exists bacon.raw_paths_terminal_unq cascade;
  delete from raw_paths;

  with
    recursive paths(path) as (
      select array[start_node, node_2]
      from edges
      where node_1 = start_node

      union all

      select p.path||e.node_2
      from edges e
      inner join paths p on e.node_1 = terminal(p.path)
      where not e.node_2 = any(p.path) -- <<<<< Prevent cycles.
      )
  insert into raw_paths(path)
  select path
  from paths;
end;
$body$;
