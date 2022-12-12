/*
  Must not use "set search_path" in the header because we want to display
  the ACTUAL search path that top-level SQLs in the present session see.
*/;
create function mgr.where_am_i()
  returns table(z text)
  security invoker
  language plpgsql
as $body$
declare
  s          constant text not null := case
                                         when current_schema() is null then 'no schema'
                                         else                               current_schema()
                                       end;

  ver        constant text not null := version();

  pg_pattern constant text not null := 'PostgreSQL [0-9]+\.[0-9]+';
  pg         constant text not null := (regexp_match(ver, pg_pattern))[1];
  pg_ver     constant text not null := replace(pg, 'PostgreSQL', 'PG');

  yb_pattern constant text not null := 'YB\-[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+';
  yb         constant text          := (regexp_match(ver, yb_pattern))[1];
  yb_ver     constant text not null := case
                                         when yb is null then 'n/a'
                                         else                 yb
                                       end;

  -- The logic here is crudely designed, but works in the range of tested environments.
  os         constant text not null := case
                                         when (ver like '%apple%')    then 'macOS'
                                         when (ver like '%Ubuntu%')   then 'Ubuntu'
                                         when (ver like '%pc-linux%') then 'Ubuntu'
                                         else                         '*** unknown ***'
                                       end;
begin
  z := '';                                                                                             return next;
  z := rpad('Database ',                    31, '.')||' '||current_database();                         return next;
  z := rpad('session_user > current_role ', 31, '.')||' '||session_user||' > '||current_role;          return next;
  z := rpad('Schema ',                      31, '.')||' '||s;                                          return next;
  z := rpad('Search path ',                 31, '.')||' '||current_setting('search_path');             return next;
  z := rpad('PG Version ',                  31, '.')||' '||pg_ver;                                     return next;
  z := rpad('YB Version ',                  31, '.')||' '||yb_ver;                                     return next;
  z := rpad('O/S ',                         31, '.')||' '||os;                                         return next;
  z := rpad('pg_backend_pid() ',            31, '.')||' '||pg_backend_pid();                           return next;
end;
$body$;

grant execute on function mgr.where_am_i() to public;
