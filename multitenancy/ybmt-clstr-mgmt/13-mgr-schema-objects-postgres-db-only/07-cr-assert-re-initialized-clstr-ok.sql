/*
  Add a test to assert that this:

    select name, setting
    from pg_settings
    where category = 'File Locations';

  gets the expected results.
*/;
--------------------------------------------------------------------------------

create type mgr.rt as (name text, super boolean, createrole boolean, createdb boolean, canlogin boolean, connlimit int);
create type mgr.dt as (name text, istemplate boolean, allowconn boolean, connlimit int);

set client_min_messages = 'warning';
create procedure mgr.assert_re_initialized_clstr_ok()
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  unexpected_roles constant text[] := (
      select array_agg(rolname)
      from pg_roles
      where rolname != 'postgres'
      and   rolname != 'clstr$mgr'
      and   rolname !~ '^pg_'
      and   rolname !~ '^yb_'
    );

  r                         mgr.rt   not null := ('', false, false, false, false, 0)::mgr.rt;
  pg_and_yb_roles  constant mgr.rt[]          := (
      select array_agg((rolname, rolsuper, rolcreaterole, rolcreatedb, rolcanlogin, rolconnlimit)::mgr.rt)
      from pg_roles
      where rolname  !~ '^pg_'
      and   rolname  !~ '^yb_'
      and   rolinherit
      and   not rolreplication
      and   not rolbypassrls
    );

  d             mgr.dt   not null := ('', false, false, 0)::mgr.dt;
  dbs  constant mgr.dt[] not null := (
      select array_agg((datname, datistemplate, datallowconn, datconnlimit)::mgr.dt)
      from pg_database
      where encoding = 6
      and datcollate::text = 'C'
      and datctype::text   = 'en_US.UTF-8'
    );
begin
  assert unexpected_roles is null,         'Unexpected roles found';
  assert cardinality(pg_and_yb_roles) = 2, 'Unexpected non-system roles count';

  -- TO_DO: Check all FIVE fields of "r".
  foreach r in array pg_and_yb_roles loop
    case r.name
      when 'postgres' then
        assert r.canlogin,   'Unexpected: "postrgres" cannot log in.';
      when 'clstr$mgr' then
        assert r.canlogin,   'Unexpected: "clstr$mgr" cannot log in.';
      else
        assert false,        'Unexpected: non-system role other than "postrgres" or "clstr$mgr" found.';
    end case;
  end loop;

  -- TO_DO: Check all THREE fields of "d".
  foreach d in array dbs loop
    case d.name
      when 'postgres' then
        null;
      when 'system_platform' then
        null;
      when 'template0' then
        null;
      when 'template1' then
        null;
    end case;
  end loop;
end;
$body$;

revoke all on procedure mgr.assert_re_initialized_clstr_ok() from public;


/*
  select
    datname,
    datistemplate::text,
    datallowconn::text,
    datconnlimit::text,
    datacl::text[]
  from pg_database
  order by datname;

  select
    datname,
    datistemplate::text,
    datallowconn::text,
    datconnlimit::text
  from pg_database
  where encoding = 6
    and datcollate::text = 'C'
    and datctype::text = 'en_US.UTF-8'
    and datacl::text[] = '{}'::text[]
  order by datname;

  datname  | datistemplate | datallowconn 
  ----------+---------------+--------------
  template0 | t             | f
  template1 | t             | f
  postgres  | f             | t
*/;

