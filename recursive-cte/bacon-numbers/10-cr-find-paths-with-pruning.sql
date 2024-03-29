call bacon.create_path_table('previous_paths', false);
call bacon.create_path_table('temp_paths',     false);

create procedure bacon.find_paths(start_node in text, prune in boolean)
  set search_path = pg_catalog, bacon, pg_temp
  language plpgsql
as $body$
declare
  n int not null := 0;
begin
  -- Emulate the non-recursive term.
  delete from raw_paths;
  delete from previous_paths;

  insert into previous_paths(path)
  select array[start_node, e.node_2]
  from edges e
  where e.node_1 = start_node;

  insert into raw_paths(path)
  select r.path from previous_paths r;

  -- Emulate the recursive term.
  loop
    delete from temp_paths;
    insert into temp_paths(path)
    select w.path||e.node_2
    from edges e
    inner join previous_paths w on e.node_1 = terminal(w.path)
    where not e.node_2 = any(w.path); -- <<<<< Prevent cycles.

    get diagnostics n = row_count;
    exit when n < 1;

    if prune then
      delete from temp_paths
      where
      (
        -- Prune all but one path to each distinct new terminal.
        path not in (select min(path) from temp_paths group by terminal(path))
      )
      or
      (
        -- Prune newer (and therefore longer) paths to
        -- already-found terminals.
        terminal(path) in
        (
          select terminal(path)
          from raw_paths
        )
      );
    end if;

    delete from previous_paths;
    insert into previous_paths(path) select t.path from temp_paths t;
    insert into raw_paths (path) select t.path from temp_paths t;
  end loop;
end;
$body$;
