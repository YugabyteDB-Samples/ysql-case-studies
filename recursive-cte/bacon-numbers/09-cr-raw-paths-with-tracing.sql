delete from raw_paths;

alter table raw_paths add column repeat_nr int;

create function raw_paths_trg_f()
  returns trigger 
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

create trigger raw_paths_trg after insert on raw_paths
for each statement
execute function raw_paths_trg_f();
