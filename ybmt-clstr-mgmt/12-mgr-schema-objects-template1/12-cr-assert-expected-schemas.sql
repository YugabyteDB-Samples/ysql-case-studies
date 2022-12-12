create procedure mgr.assert_expected_schemas()
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  s text;
  o text;
  r text;
  mgr_found         boolean not null := false;
  extensions_found  boolean not null := false;
  dt_utils_found    boolean not null := false;
begin
  for s, o in (
    select n.nspname::text, r1.rolname::text
    from pg_namespace n inner join pg_roles r1 on n.nspowner = r1.oid
    where nspname !~ 'information_schema' and nspname !~ '^pg_')
  loop
    case s
      when 'mgr' then
        mgr_found := true;
        assert o = 'clstr$mgr', 'Unexpected: schema "mgr" should be owned by "clstr$mgr": "'||o||'"';

      when 'extensions' then
        extensions_found := true;
        assert o = 'clstr$mgr', 'Unexpected: schema "extensions" should be owned by "clstr$mgr": "'||o||'"';

      when 'dt_utils' then
        dt_utils_found := true;
        assert o = 'clstr$mgr', 'Unexpected: schema "dt_utils" should be owned by "clstr$mgr": "'||o||'"';

      else
        assert false, 'Found unexpected schema: "'||s||'"';
    end case;
  end loop;

  select distinct owner into r from mgr.schema_objects where name::text != 'set_tenant_database_setting';
  assert r = 'clstr$mgr', 'Unexpected: all objects "mgr" in "'||current_database()||
                          ' except for "set_tenant_database_setting()" if it exists should be'||
                          ' owned by "clstr$mgr" and not: "'||r||'"';

  case current_database()
    when 'yugabyte' then
      assert mgr_found and not extensions_found, 'Unexpected: database "yugabyte" should have only the "mgr" schema';

    when 'template1' then
      assert mgr_found and extensions_found and dt_utils_found,
        'Unexpected: database "yugabyte" should have'||
        ' all of the "mgr", "extensions", and "dt_utils" schemas.';
      select r2.rolname
      into r
      from
        pg_proc p
        inner join
        pg_namespace nn
        on p.pronamespace = nn.oid
        inner join
        pg_roles r2
        on p.proowner = r2.oid
      where p.proname = 'set_tenant_database_setting'
      and   nn.nspname = 'mgr';

      assert r is not null, 'Unexpected: procedure "set_tenant_database_setting()" not found.';

      assert r = 'yugabyte', 'Unexpected: procedure "set_tenant_database_setting()"'||
                              ' should be owned by "yugabyte" not: "'||r||'"';

    else
      assert false, '"mgr.assert_expected_schemas()" programming error for: "'||current_database()||'"';
  end case;
end;
$body$;
revoke all on procedure mgr.assert_expected_schemas() from public;
