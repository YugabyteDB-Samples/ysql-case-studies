--------------------------------------------------------------------------------
-- This function is crudely designed, but works.
--   For "PG Version"... it looks to find either 'PostgreSQL 11.2' or 'PostgreSQL 14.4'.
--   For "YB Version"... it looks to find either 'YB-2.4.0.0' or 'YB-2.15.2.0'.
--   For "O/S".......... it looks to find either 'apple' or 'Ubuntu' or 'x86_64-pc-linux-gnu'

create function mgr.where_am_i()
  returns table(
    "Database"                     text,
    "session_user > current_role"  text,
    "Schema"                       text,
    "Search Path"                  text,
    "PG Version"                   text,
    "YB Version"                   text,
    "O/S"                          text,
    "pg_backend_pid()"             int)

  volatile
  security invoker
  language plpgsql
as $body$
declare
  s constant text := current_schema();
begin
  "Database"                    := current_database();
  "session_user > current_role" := session_user||' > '||current_role;
  "Schema"   :=
    case s
      when null then 'no schema'
      else           s
    end;

  "Search Path" := current_setting('search_path');

  -- Need to fix for Ubuntu
  "PG Version" := (
    select
      case
        when (select position('PostgreSQL 11.18' in version())) > 0 then 'PostgreSQL 11.18'
        when (select position('PostgreSQL 11.2'  in version())) > 0 then 'PostgreSQL 11.2'
        when (select position('PostgreSQL 14.5'  in version())) > 0 then 'PostgreSQL 14.5'
        else                                                            '*** unknown ***'
      end);

  "YB Version" := (
    select
      case
        when(select position('YB-2.15.3.2' in version())) > 0 then 'YB-2.15.3.2'
        else                                                       '*** n/a ***'
      end);

  "O/S" := (
    select
      case
        when(select position('apple' in version())) > 0 then
          'macOS'
        when(select position('Ubuntu' in version())) > 0 then
          'Ubuntu'
        when (select position('x86_64-pc-linux-gnu' in version())) > 0 then
         'Ubuntu'
        else '*** unknown ***'
      end);

    "pg_backend_pid()" := pg_backend_pid();

  return next;
end;
$body$;

grant execute on function mgr.where_am_i() to public;
