/*
  This will be owned by the "yugabyte" superuser. (The implicitly created temporary
  schemas are owned by the bootstrap super user.)
*/;
create procedure mgr.drop_all_temp_schemas()
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  s name;
begin
  for s in (
    select t.schema from mgr.temp_schemas as t)
  loop
    execute format('drop schema %I', s); 
  end loop;
end;
$body$;

revoke all on procedure mgr.drop_all_temp_schemas() from public;
