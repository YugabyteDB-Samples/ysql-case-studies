drop procedure if exists cr_staging_tables() cascade;

create procedure cr_staging_tables()
  language plpgsql
as $body$
declare
  drop_table constant text := '
    drop table if exists %I cascade';

  create_staging_table constant text := '
    create table %I(
      code         int     not null,
      geo_value    text    not null,
      signal       text    not null,
      time_value   date    not null,
      direction    text,
      issue        date    not null,
      lag          int     not null,
      value        numeric not null,
      stderr       numeric not null,
      sample_size  numeric not null,
      geo_type     text    not null,
      data_source  text    not null,
      constraint "%s_pk" primary key(geo_value, time_value))
    ';

  names constant text[] not null := (
    select array_agg(staging_table) from covidcast_names);
  name text not null := '';
begin
  foreach name in array names loop
    execute format(drop_table, name);

    execute format(create_staging_table, name, name);
  end loop;
end;
$body$;
