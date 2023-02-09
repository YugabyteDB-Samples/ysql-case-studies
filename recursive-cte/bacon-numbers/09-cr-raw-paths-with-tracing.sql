delete from bacon.raw_paths;

alter table bacon.raw_paths add column repeat_nr int;

create function bacon.raw_paths_trg_f()
  returns trigger
  set search_path = pg_catalog, bacon, pg_temp
  language plpgsql
as $body$
declare
  max_iteration constant int := (
    select coalesce(max(repeat_nr), null, -1) + 1 from raw_paths);
begin
  update raw_paths set repeat_nr = max_iteration where repeat_nr is null;
  return new;
end;
$body$;

create trigger raw_paths_trg after insert on bacon.raw_paths
for each statement
execute function bacon.raw_paths_trg_f();
