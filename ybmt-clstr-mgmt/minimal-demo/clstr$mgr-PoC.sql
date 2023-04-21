\ir mini.sql
\c :db yugabyte
set client_min_messages = error;

-- No errors!
drop owned by d9$code cascade;

--------------------------------------------------------------------------------
-- Repeat, authorizing as "clstr$mgr" rather then as "yugabyte".

\set VERBOSITY verbose

\ir mini.sql
\c :db clstr$mgr
set client_min_messages = error;

do $body$
begin
  drop owned by d9$code cascade;
exception when insufficient_privilege then
  declare
    msg text not null := '';
  begin
    get stacked diagnostics msg = message_text;
    assert msg = 'permission denied to drop objects';
  end;
end;
$body$;

grant d9$code to clstr$mgr;
do $body$
begin
  drop owned by d9$code cascade;
exception when insufficient_privilege then
  declare
    msg text not null := '';
  begin
    get stacked diagnostics msg = message_text;
    assert msg = 'permission denied for column "tableoid" of relation "t_k_seq"';
  end;
end;
$body$;

select name from mgr.tenant_roles where not mgr.is_reserved(name);

grant d9$data to clstr$mgr;
drop owned by d9$code cascade;

----------------------------------------------------------------------
/*
  Notice that a role without "superuser" but with "createrole" is
  still dangerously powerful because it can grant itself built-in
  roles like "pg_execute_server_program", "pg_read_server_files",
  and "pg_write_server_files"
*/;

grant  pg_execute_server_program  to clstr$mgr;
grant  pg_read_server_files       to clstr$mgr;
grant  pg_write_server_files      to clstr$mgr;
