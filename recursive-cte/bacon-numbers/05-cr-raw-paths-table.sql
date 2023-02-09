create procedure bacon.create_path_table(name in text, temp in boolean)
  set search_path = pg_catalog, bacon, pg_temp
  language plpgsql
as $body$
declare
  drop_table constant text := '
    drop table if exists %I cascade';

  create_table constant text := '
    create table bacon.%I(
      k     serial  primary key,
      path  text[]  not null)';

  create_temp_table constant text := '
    create temporary table %I(
      k     serial  primary key,
      path  text[]  not null)';

  cache_sequence constant text := '
    alter sequence %I cache 100000';
begin
  execute format(drop_table, name);
  case temp
    when true then execute format(create_temp_table, name);
    else           execute format(create_table,      name);
  end case;
  execute format(cache_sequence, name||'_k_seq');
end;
$body$;

call bacon.create_path_table('raw_paths', false);
