do $body$
declare
  s text;
begin
  for s in (
    select nspname
    from pg_namespace
    where nspname !~ 'pg_'
    and   nspname !~ 'yb_'
    and   nspname != 'information_schema')
  loop
    execute format('drop schema %I cascade;', s);
  end loop;
end;
$body$;

create schema mgr authorization yugabyte;
revoke all on schema mgr from public;

alter database template1 with allow_connections true connection limit 2;
\c template1 yugabyte
set client_min_messages = 'warning';

do $body$
declare
  s text;
begin
  for s in (
    select nspname
    from pg_namespace
    where nspname !~ 'pg_'
    and   nspname !~ 'yb_'
    and   nspname != 'information_schema')
  loop
    execute format('drop schema %I cascade;', s);
  end loop;
end;
$body$;

\c yugabyte yugabyte
set client_min_messages = 'warning';
alter database template1 with allow_connections false connection limit 0;
