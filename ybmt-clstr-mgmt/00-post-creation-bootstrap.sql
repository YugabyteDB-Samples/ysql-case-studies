\set VERBOSITY verbose
\set ON_ERROR_STOP true
\t off
\x off
--------------------------------------------------------------------------------
\c postgres postgres
set client_min_messages = 'warning';

drop database if exists yugabyte;

do $body$
begin
  drop owned by yugabyte cascade;
exception
  when undefined_object then null;
end;
$body$;

alter database template1 with allow_connections = true;

\c template1 postgres
set client_min_messages = 'warning';

do $body$
begin
  drop owned by yugabyte cascade;
exception
  when undefined_object then null;
end;
$body$;

\c postgres postgres
set client_min_messages = 'warning';
alter database template1 with allow_connections = false;

drop role if exists yugabyte;

create role yugabyte with
  superuser
  nocreaterole
  nocreatedb
  noreplication
  nobypassrls
  connection limit -1
  login password 'x';

create database yugabyte with
  owner = postgres allow_connections = true;

\c yugabyte yugabyte
set client_min_messages = 'warning';
drop database postgres;
alter role postgres with superuser connection limit -1 login password null;
