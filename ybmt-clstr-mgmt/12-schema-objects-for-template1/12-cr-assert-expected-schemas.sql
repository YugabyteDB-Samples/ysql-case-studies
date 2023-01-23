create procedure mgr.assert_expected_schemas()
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  s text;
  o text;
  r text;
  client_safe_found  boolean not null := false;
  mgr_found          boolean not null := false;
  extensions_found   boolean not null := false;
  dt_utils_found     boolean not null := false;
begin
  for s, o in (
    select n.nspname::text, r1.rolname::text
    from pg_namespace n inner join pg_roles r1 on n.nspowner = r1.oid
    where nspname !~ 'information_schema' and nspname !~ '^pg_')
  loop
    case s
      when 'client_safe' then
        client_safe_found := true;
        assert o = 'clstr$mgr', 'Unexpected: schema "client_safe" should be owned by "clstr$mgr": "'||o||'"';

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

  for r in (
    select distinct owner
    from mgr.schema_objects
    where name::text != all(array['set_tenant_database_setting', 'drop_all_temp_schemas']))
  loop
    assert r = 'clstr$mgr', 'Unexpected: all objects in schema "mgr" in "'||current_database()||
                            ' except for "set_tenant_database_setting()" if it exists'||
                            ' and "drop_all_temp_schemas()"'||
                            ' should be owned by "clstr$mgr" and not: "'||r||'"';
  end loop;

  for r in (
    select distinct owner
    from mgr.schema_objects
    where name::text = any(array['set_tenant_database_setting', 'drop_all_temp_schemas']))
  loop
    assert r = 'yugabyte', 'The objects "set_tenant_database_setting()" if it exists'||
                            ' and "drop_all_temp_schemas()"'||
                            ' in the "mgr" schema in "'||current_database()||
                            ' should be owned by "yugabyte" and not: "'||r||'"';
  end loop;

  case current_database()
    when 'yugabyte' then
      assert mgr_found and not extensions_found, 'Unexpected: database "yugabyte" should have only the "mgr" schema';

    when 'template1' then
      assert mgr_found and extensions_found and dt_utils_found,
        'Unexpected: database "yugabyte" should have'||
        ' all of the "mgr", "extensions", and "dt_utils" schemas.';
    else
      assert false, '"mgr.assert_expected_schemas()" programming error for: "'||current_database()||'"';
  end case;
end;
$body$;
revoke all on procedure mgr.assert_expected_schemas() from public;
