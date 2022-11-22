do $body$
begin
  drop owned by clstr$mgr cascade;
exception when undefined_object
  then null;
end;
$body$;

drop role if exists clstr$mgr;

create role clstr$mgr with
  nosuperuser
  createrole
  createdb
  noreplication
  nobypassrls
  connection limit -1
  login password 'x';

grant connect on database postgres to clstr$mgr;
grant create  on database postgres to clstr$mgr;
alter role clstr$mgr set search_path = mgr, pg_catalog, pg_temp;
