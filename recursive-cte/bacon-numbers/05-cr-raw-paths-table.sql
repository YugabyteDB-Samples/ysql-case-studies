create procedure create_path_table(name in text, temp in boolean)
  language plpgsql
as $body$
declare
  drop_table constant text := '
    drop table if exists ? cascade';

  create_table constant text := '
    create table ?(
      k     serial  primary key,
      path  text[]  not null)';

  create_temp_table constant text := '
    create temporary table ?(
      k     serial  primary key,
      path  text[]  not null)';

  cache_sequence constant text := '
    alter sequence ?_k_seq  cache 100000';
begin
  execute replace(drop_table,     '?', name);
  case temp
    when true then execute replace(create_temp_table, '?', name);
    else           execute replace(create_table,      '?', name);
  end case;
  execute replace(cache_sequence, '?', name);
end;
$body$;

call create_path_table('raw_paths', false);
