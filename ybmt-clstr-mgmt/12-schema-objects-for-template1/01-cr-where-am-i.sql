create procedure client_safe.where_am_i_version(pg_ver inout text, yb_ver inout text, os inout text)
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  ver        constant text not null := version();

  pg_pattern constant text not null := 'PostgreSQL [0-9]+\.[0-9]+';
  pg         constant text not null := (regexp_match(ver, pg_pattern))[1];
  pg_ver_    constant text not null := replace(pg, 'PostgreSQL', 'PG');

  yb_pattern constant text not null := 'YB\-[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+';
  yb         constant text          := (regexp_match(ver, yb_pattern))[1];
  yb_ver_    constant text not null := case
                                         when yb is null then 'n/a'
                                         else                 yb
                                       end;

  -- The logic here is crudely designed, but works in the range of tested environments.
  os_        constant text not null := case
                                         when (ver like '%apple%')    then 'macOS'
                                         when (ver like '%Ubuntu%')   then 'Ubuntu'
                                         when (ver like '%pc-linux%') then 'Ubuntu'
                                         else                         '*** unknown ***'
                                       end;
begin
  pg_ver := pg_ver_;
  yb_ver := yb_ver_;
  os     := os_;
end;
$body$;
revoke all     on procedure client_safe.where_am_i_version(text, text, text) from public;
grant  execute on procedure client_safe.where_am_i_version(text, text, text) to   public;
------------------------------------------------------------------------------------------------------------------------

/*
  Must not use "set search_path" in the header because we want to display
  the ACTUAL search path that top-level SQLs in the present session see.

  This must be a "security invoker" function so that "current_setting('search_path')"
  sees that value that it needs to.
*/;
create function mgr.where_am_i()
  returns table(z text)
  security invoker
  language plpgsql
as $body$
declare
  s       constant text not null := case
                                      when current_schema() is null then 'no schema'
                                      else                               current_schema()::text
                                    end;

  db      constant text not null := current_database()::text;
  s_usr   constant text not null := session_user::text;
  c_role  constant text not null := current_role::text;

  pg_ver           text not null := '';
  yb_ver           text not null := '';
  os               text not null := '';

  pid     constant text not null := pg_backend_pid()::text;
begin
  call client_safe.where_am_i_version(pg_ver, yb_ver, os);

  z := '';                                                                                        return next;
  z := rpad('Database ',                    31, '.')||' '||db;                                    return next;
  z := rpad('session_user > current_role ', 31, '.')||' '||s_usr||' > '||c_role;                  return next;
  z := rpad('Schema ',                      31, '.')||' '||s;                                     return next;
  z := rpad('Search path ',                 31, '.')||' '||current_setting('search_path');        return next;
  z := rpad('PG Version ',                  31, '.')||' '||pg_ver;                                return next;
  z := rpad('YB Version ',                  31, '.')||' '||yb_ver;                                return next;
  z := rpad('O/S ',                         31, '.')||' '||os;                                    return next;
  z := rpad('pg_backend_pid() ',            31, '.')||' '||pid;                                   return next;
end;
$body$;

grant execute on function mgr.where_am_i() to public;
------------------------------------------------------------------------------------------------------------------------

/*
  Must not use "set search_path" in the header because we want to display
  the ACTUAL search path that top-level SQLs in the present session see.

  This must be a "security invoker" function so that "current_setting('search_path')"
  sees that value that it needs to.
*/;
create function client_safe.where_am_i_simple()
  returns table(z text)
  security invoker
  language plpgsql
as $body$
declare
  db      constant text not null := current_database()::text;
  s_usr   constant text not null := session_user::text;
  c_role  constant text not null := current_role::text;

  pg_ver           text not null := '';
  yb_ver           text not null := '';
  os               text not null := '';
begin
  call client_safe.where_am_i_version(pg_ver, yb_ver, os);
  z := '';                                                                              return next;
  z := rpad('Database ',                    31, '.')||' '||db;                          return next;
  z := rpad('session_user > current_role ', 31, '.')||' '||s_usr||' > '||c_role;        return next;
  z := rpad('PG Version ',                  31, '.')||' '||pg_ver;                      return next;
  z := rpad('YB Version ',                  31, '.')||' '||yb_ver;                      return next;
  z := rpad('O/S ',                         31, '.')||' '||os;                          return next;
end;
$body$;

grant execute on function client_safe.where_am_i_simple() to public;
