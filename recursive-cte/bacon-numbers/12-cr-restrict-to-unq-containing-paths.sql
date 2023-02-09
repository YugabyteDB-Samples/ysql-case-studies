-- Filter the input set of paths to set of longest paths
-- that jointly contain all the other paths.
create procedure bacon.restrict_to_unq_containing_paths(
  in_tab in text, out_tab in text, append in boolean default false)
  set search_path = pg_catalog, bacon, pg_temp
  language plpgsql
as $body$
declare
  stmt constant text := '
    with
      -- Cartesian product restricted to give all possible
      -- longer path with shorter path combinations.
      each_path_with_all_shorter_paths as (
        select a1.path as longer_path, a2.path as shorter_path
        from %1$I as a1, %1$I as a2
        where cardinality(a1.path) > cardinality(a2.path)),

      -- Identify each shorter path that is contained by
      -- its longer path partner.
      contained_paths as (
        select
        shorter_path as contained_path
        from each_path_with_all_shorter_paths
        where longer_path @> shorter_path)

    -- Filter out the contained paths.
    insert into %2$I(path)
    select path
    from %1$I
    where path not in (
      select contained_path from contained_paths
      )';
begin
  case append
    when false then execute 'delete from '||out_tab;
    else            null;
  end case;
  execute format(stmt, in_tab, out_tab);
end;
$body$;
