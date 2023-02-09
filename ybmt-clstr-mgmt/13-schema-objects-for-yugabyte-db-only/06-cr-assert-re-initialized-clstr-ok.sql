create type mgr.rt as (name text, super boolean, createrole boolean, createdb boolean, inherit boolean, canlogin boolean, connlimit int, config text[]);
create type mgr.dt as (name text, istemplate boolean, allowconn boolean, connlimit int, acl text[]);

create procedure mgr.assert_re_initialized_clstr_ok()
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  postgres_role_found         boolean not null := false;
  yugabyte_role_found         boolean not null := false;
  clstr$mgr_role_found        boolean not null := false;
  clstr$developer_role_found  boolean not null := false;
 
  yugabyte_db_found           boolean not null := false;
  system_platform_db_found    boolean not null := false;
  template0_db_found          boolean not null := false;
  template1_db_found          boolean not null := false;

  r              mgr.rt   not null := ('', false, false, false, false, false, 0, '{}'::text[])::mgr.rt;
  roles constant mgr.rt[]          := (
      select array_agg((rolname, rolsuper, rolcreaterole, rolcreatedb, rolinherit, rolcanlogin, rolconnlimit, rolconfig)::mgr.rt)
      from pg_roles
      where rolname  !~ '^pg_'
      and   rolname  !~ '^yb_'
      and   not rolreplication
      and   not rolbypassrls
    );

  d            mgr.dt   not null := ('', false, false, 0, '{}'::text[])::mgr.dt;
  dbs constant mgr.dt[] not null := (
      select array_agg((dd.datname, dd.datistemplate, dd.datallowconn, dd.datconnlimit, dd.datacl)::mgr.dt)
      from pg_database dd inner join pg_roles rr on dd.datdba= rr.oid
      where rr.rolname = 'postgres'
      and   encoding = 6
      and   datcollate::text = 'C'
      and   datctype::text   = 'en_US.UTF-8'
    );
begin
  ----------------------------------------------------------------------------------------------------------------------
  -- Check the roles.
  foreach r in array roles loop
    case r.name
      when 'postgres' then
        postgres_role_found := true;
        assert r.super,          'Unexpected: "postgres" should be superuser.';
        assert not r.createrole, 'Unexpected: "postgres" should have "rolcreaterole = false".';
        assert not r.createdb,   'Unexpected: "postgres" should have "rolcreatedb = false".';
        assert not r.inherit,    'Unexpected: "postgres" should have "rolinherit  = false".';

        /*
          Workaround to allow index backfill.
          assert not r.canlogin,    'Unexpected: "postgres" CAN log in.';
        */
        assert r.canlogin,          'Unexpected: "postgres" cannot log in.';
        assert r.connlimit = -1,    'Unexpected: "postgres" should have "connlimit = -1": '|| r.connlimit::text;

        assert cardinality(r.config) = 1,
          'Unexpected: "cardinality(r.config)" for "postgres": '||
          cardinality(r.config)::text;
        assert (r.config)[1] = 'search_path=pg_catalog, client_safe, dt_utils, mgr, extensions, pg_temp',
          'Unexpected for "postgres": '||(r.config)[1];

      when 'yugabyte' then
        yugabyte_role_found := true;
        assert r.super,          'Unexpected: "yugabyte" should be superuser.';
        assert not r.createrole, 'Unexpected: "yugabyte" should have "rolcreaterole = false".';
        assert not r.createdb,   'Unexpected: "yugabyte" should have "rolcreatedb = false".';
        assert not r.inherit,    'Unexpected: "yugabyte" should have "rolinherit  = false".';
        assert r.canlogin,       'Unexpected: "yugabyte" cannot log in.';
        assert r.connlimit = 0,  'Unexpected: "yugabyte" should have "connlimit = 0": '|| r.connlimit::text;

        assert cardinality(r.config) = 1,
          'Unexpected: "cardinality(r.config)" for "yugabyte": '||
          cardinality(r.config)::text;
        assert (r.config)[1] = 'search_path=pg_catalog, client_safe, dt_utils, mgr, extensions, pg_temp',
          'Unexpected for "yugabyte": '||(r.config)[1];

      when 'clstr$mgr' then
        clstr$mgr_role_found := true;
        assert not r.super,      'Unexpected: "clstr$mgr" should NOT be superuser.';
        assert r.createrole,     'Unexpected: "clstr$mgr" should have "rolcreaterole = true".';
        assert r.createdb,       'Unexpected: "clstr$mgr" should have "rolcreatedb = true".';
        assert r.inherit,        'Unexpected: "clstr$mgr" should have "rolinherit  = true".';
        assert r.canlogin,       'Unexpected: "clstr$mgr" cannot log in.';
        assert r.connlimit = -1, 'Unexpected: "clstr$mgr" should have "connlimit = -1": '|| r.connlimit::text;

        assert cardinality(r.config) = 1,
          'Unexpected: "cardinality(r.config)" for "clstr$mgr": '||
          cardinality(r.config)::text;
        assert (r.config)[1] = 'search_path=pg_catalog, client_safe, dt_utils, mgr, extensions, pg_temp',
          'Unexpected for "clstr$mgr": '||(r.config)[1];

      when 'clstr$developer' then
        clstr$developer_role_found := true;
        assert not r.super,      'Unexpected: "clstr$developer" should NOT be superuser.';
        assert not r.createrole, 'Unexpected: "clstr$developer" should have "rolcreaterole = false".';
        assert not r.createdb,   'Unexpected: "clstr$developer" should have "rolcreatedb = false".';
        assert not r.inherit,    'Unexpected: "clstr$developer" should have "rolinherit  = false".';
        assert not r.canlogin,   'Unexpected: "clstr$developer" CAN log in.';
        assert r.connlimit = 0,  'Unexpected: "clstr$developer" should have "connlimit = 0": '|| r.connlimit::text;

        assert r.config is null,
          'Unexpected: "r.config" for "clstr$developer" is not null';

      else
        assert false,
          'Unexpected: non-system role other than "postgres", "yugabyte", "clstr$mgr", or "clstr$developer" found: '||
          r.name;
    end case;
  end loop;

  assert postgres_role_found,  'Role "postgres" is missing';
  assert yugabyte_role_found,  'Role "yugabyte" is missing';
  assert clstr$mgr_role_found, 'Role "clstr$mgr" is missing';

  ----------------------------------------------------------------------------------------------------------------------
  -- Check the databases.
  foreach d in array dbs loop
    case d.name
      when 'yugabyte' then
        yugabyte_db_found := true;
        assert not d.istemplate,       'Unexpected: database "yugabyte" should NOT be a template.';
        assert d.allowconn,            'Unexpected: database "yugabyte" should allow connections.';
        assert d.connlimit = -1,       'Unexpected: database "yugabyte" should have "connection limit" = -1.';
        assert cardinality(d.acl) = 1, 'Unexpected: database "yugabyte" should have "cardinality(datacl)" = 1.';
        /*
          The fact that the grantor of "connect" and for "clstr$mgr" is nominaly "postgres"
          is of no consequence. The grants were actually done by "yugabyte". But "postgres" is the owner
          of the "yugabyte" database.

          This is the most compact code for this check. You could use "aclexplode()", check that
          it produces just a single row, and check that this shows:
            grantee='clstr$mgr', privilege_type='connect', is_grantable=false, grantor= 'postgres'.
          But this would be noticeably more code. It's OK, here, to trust the humanly-readable rendering
          that an aclitem value encodes.
        */
        assert (d.acl)[1] = '"clstr$mgr"=c/postgres',
          'Unexpected: database "yugabyte" should allow "connect" (and only this) for "clstr$mgr": '||(d.acl)[1];

      when 'system_platform' then
        system_platform_db_found := true;
        assert not d.istemplate,       'Unexpected: database "system_platform" should NOT be a template.';
        assert not d.allowconn,        'Unexpected: database "system_platform" should NOT allow connections.';
        assert d.connlimit = 0 ,       'Unexpected: database "system_platform" should have "connection limit" = 0.';
        assert cardinality(d.acl) = 0, 'Unexpected: database "yugabyte" should have "cardinality(datacl)" = 0.';

      when 'template0' then
        template0_db_found := true;
        assert d.istemplate,           'Unexpected: database "template0" should be a template.';
        assert not d.allowconn,        'Unexpected: database "template0" should NOT allow connections.';
        assert d.connlimit = 0 ,       'Unexpected: database "template0" should have "connection limit" = 0.';
        assert cardinality(d.acl) = 0, 'Unexpected: database "template0" should have "cardinality(datacl)" = 0.';

      when 'template1' then
        template1_db_found := true;
        assert d.istemplate,           'Unexpected: database "template1" should be a template.';
        assert not d.allowconn,        'Unexpected: database "template1" should NOT allow connections.';
        assert d.connlimit = 0 ,       'Unexpected: database "template1" should have "connection limit" = 0.';
        assert cardinality(d.acl) = 0, 'Unexpected: database "template1" should have "cardinality(datacl)" = 0.';

      else
        assert false, 
          'Unexpected: database other than "yugabyte", "system_platform", "template0", or "template1" found: '||
          d.name;
    end case;
  end loop;

  assert yugabyte_db_found,   'Database "yugabyte" is missing';
  assert template0_db_found,  'Database "template0" is missing';
  assert template1_db_found,  'Database "template1" is missing';

  case version() like '%YB%'
    when true  then assert system_platform_db_found,     'Database "system_platform" is missing';
    when false then assert not system_platform_db_found, 'Database "system_platform" is wrongly present';
  end case;
end;
$body$;
revoke all on procedure mgr.assert_re_initialized_clstr_ok() from public;
