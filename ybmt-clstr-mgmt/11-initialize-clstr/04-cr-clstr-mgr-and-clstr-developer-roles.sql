alter database template1 with allow_connections true connection limit 2;
\c template1 yugabyte
set client_min_messages = 'warning';
\ir 03-drop-owned-by-clstr-mgr-and-clstr-developer-roles.sql

\c yugabyte yugabyte
set client_min_messages = 'warning';
\ir 03-drop-owned-by-clstr-mgr-and-clstr-developer-roles.sql

drop role if exists clstr$mgr;
create role clstr$mgr;

drop role if exists clstr$developer;
create role clstr$developer;

grant clstr$developer to clstr$mgr with admin option;
