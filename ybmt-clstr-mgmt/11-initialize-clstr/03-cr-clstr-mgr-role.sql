do $body$
begin
  drop owned by clstr$mgr cascade;
exception when undefined_object
  then null;
end;
$body$;

drop role if exists clstr$mgr;
create role clstr$mgr;
