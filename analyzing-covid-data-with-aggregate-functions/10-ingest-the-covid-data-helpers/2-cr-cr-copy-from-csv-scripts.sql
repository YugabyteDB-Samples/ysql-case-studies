drop function if exists cr_copy_from_scripts(int) cascade;

create function cr_copy_from_scripts(which in int)
  returns text
  language plpgsql
as $body$
<<b>>declare
  copy_from_csv constant text :=
    $$\copy %I from %L with (format 'csv', header true);$$;

  csv_file       text not null := '';
  staging_table  text not null := '';
begin
  with a as (
    select
      row_number() over (order by s.csv_file) as r,
      s.csv_file,
      s.staging_table
    from covidcast_names as s)
  select a.csv_file, a.staging_table
  into b.csv_file, b.staging_table
  from a where a.r = which;

  return format(copy_from_csv, staging_table, csv_file);
end b;
$body$;
