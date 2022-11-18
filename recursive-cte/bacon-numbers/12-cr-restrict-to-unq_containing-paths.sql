-- Filter the input set of paths to set of longest paths
-- that jointly contain all the other paths.
create procedure restrict_to_unq_containing_paths(
  in_tab in text, out_tab in text, append in boolean default false)
  language plpgsql
as $body$
declare
  stmt constant text := '
    with
      -- Cartesian product restricted to give all possible
      -- longer path with shorter path combinations.
      each_path_with_all_shorter_paths as (
        select a1.path as longer_path, a2.path as shorter_path
        from ?in_tab as a1, ?in_tab as a2
        where cardinality(a1.path) > cardinality(a2.path)),

      -- Identify each shorter path that is contained by
      -- its longer path partner.
      contained_paths as (
        select
        shorter_path as contained_path
        from each_path_with_all_shorter_paths
        where longer_path @> shorter_path)

    -- Filter out the contained paths.
    insert into ?out_tab(path)
    select path
    from ?in_tab
    where path not in (
      select contained_path from contained_paths
      )';
begin
  case append
    when false then execute 'delete from '||out_tab;
    else            null;
  end case;
  execute replace(replace(stmt, '?in_tab', in_tab), '?out_tab', out_tab);
end;
$body$;


call create_path_table('unq_containing_paths', false);
call restrict_to_unq_containing_paths('raw_paths', 'unq_containing_paths');

\t on
select t from list_paths('unq_containing_paths');
\t off
