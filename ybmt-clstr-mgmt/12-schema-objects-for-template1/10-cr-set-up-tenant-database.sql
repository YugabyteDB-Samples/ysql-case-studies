/*
  Notice that "drop_role()", "cr_role()", and "set_role_password()"
  will reject values for the "nickname" formal that have "is_good_rolename()" FALSE.
*/;
create procedure mgr.set_up_tenant_database()
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  /*
    "current_database()" is, by construction, the "tenant database"
    that this procedure will set up.
  */
  db constant text not null := current_database();

  mgr_role        constant text not null := db||'$'||mgr.good_role_nickname('mgr');
  client_role     constant text not null := db||'$'||mgr.good_role_nickname('client');

  database_db_comment constant text not null :=
    '"tenant" database for ad hoc, throw-away tests, i.e. for play. '             ||e'\n';

  role_db$mgr_comment constant text not null := format(
    'Tenant role for the "%s" database for managing tenant roles there. '         ||e'\n'||
    'Owns no schema. Could own extra objects in the "mgr" schema  '               ||e'\n'||
    'than "template1" brings. Has "execute" on these procedures:  '               ||e'\n'||
    '"cr_role()", "drop_role". "mgr.set_role_password()".  '                      ||e'\n',
    db);

  role_db$client_comment constant text not null := format(
    'Tenant role. Client-side code will authorize as this to connect to '         ||e'\n'||
    'the "%s" database. Owns no objects. Is the grantee for the '                 ||e'\n'||
    'designed set of object privileges that expose the client-facing API. '       ||e'\n',
    db);
begin
  assert current_role = 'clstr$mgr',
    'You must authorize as "current_role" to call "set_up_tenant_database()"';

  -- Belt and braces.
  execute format($$alter role all in database %I set client_min_messages = warning$$, db);

  assert mgr.is_good_tenant_role_name(mgr_role),       'Bad tenant role name: '||mgr_role;
  assert mgr.is_good_tenant_role_name(client_role),    'Bad tenant role name: '||client_role;

  /*
    These settings are not copied from "template1".
  */
  execute format($$alter database %I set client_min_messages   = 'warning';                                          $$, db);
  execute format($$alter database %I set search_path = pg_catalog, client_safe, dt_utils, mgr, extensions, pg_temp;  $$, db);
  execute format($$alter database %I set transaction_isolation = 'read committed';                                   $$, db);

  call mgr.set_tenant_database_setting(db, 'log_error_verbosity', 'verbose');
  execute format($$revoke all on database %I from public;                          $$, db);
  execute format($$grant  all on database %I to clstr$mgr with grant option;       $$, db);

  declare
    db$mgr_exists boolean not null :=
      exists(select 1 from pg_roles where rolname = mgr_role);

    db$client_exists boolean not null :=
      exists(select 1 from pg_roles where rolname = client_role);
  begin
    if db$mgr_exists then
      execute format('grant %I to clstr$mgr;',     mgr_role);
      execute format('drop owned by %I cascade;',  mgr_role);
      execute format('drop role %I;',              mgr_role);
    end if;

    if db$client_exists then
      execute format('grant %I to clstr$mgr;',     client_role);
      execute format('drop owned by %I cascade;',  client_role);
      execute format('drop role %I;',              client_role);
    end if;
  end;

  --------------------------------------------------------------------------------------------------
  -- Create the <db>$mgr role.

  execute format('
    create role %I with
      nocreatedb
      nocreaterole
      inherit
      noreplication
      nobypassrls
      connection limit -1
      in role %I
      login password ''m'';',
      mgr_role, 'clstr$developer');

  execute format('alter role %I set search_path = pg_catalog, client_safe, dt_utils, mgr, extensions, pg_temp;',     mgr_role);
  execute format('grant all on database %I to %I;',                                                              db, mgr_role);

  execute format('grant execute on procedure mgr.comment_on_current_db(text) to %I;',                                mgr_role);

  execute format('grant execute on procedure mgr.cr_role(text, boolean, boolean, text) to %I;',                      mgr_role);
  execute format('grant execute on procedure mgr.drop_role(text) to %I;',                                            mgr_role);
  execute format('grant execute on procedure mgr.drop_all_regular_local_roles() to %I;',                             mgr_role);
  --------------------------------------------------------------------------------
  -- Create the <db>$client role.

  execute format('
    create role %I with
      nocreatedb
      nocreaterole
      noinherit
      noreplication
      nobypassrls
      connection limit -1
      login password ''c'';',
      client_role);

  execute format('alter role %I set search_path = pg_catalog, client_safe, pg_temp;',      client_role);
  execute format('grant connect on database %I to %I;',                                db, client_role);
  --------------------------------------------------------------------------------

  execute format('comment on database %I is %L',   db,             database_db_comment      );
  execute format('comment on role     %I is %L',   mgr_role,       role_db$mgr_comment      );
  execute format('comment on role     %I is %L',   client_role,    role_db$client_comment   );

  --------------------------------------------------------------------------------
  -- This is a hygiene practice. A temporary schema is created on demand and dropped
  -- when the session the created it ends. It's nice to be able to confirm that
  -- this is the case by querying the "mgr.temp_schemas" view.
  call mgr.drop_all_temp_schemas();
end;
$body$;

revoke all on procedure mgr.set_up_tenant_database() from public;
