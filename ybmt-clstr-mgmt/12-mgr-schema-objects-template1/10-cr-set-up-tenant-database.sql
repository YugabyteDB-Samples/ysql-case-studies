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
  developer_role  constant text not null := db||'$'||mgr.good_role_nickname('developer');
  client_role     constant text not null := db||'$'||mgr.good_role_nickname('client');

  database_db_comment constant text not null :=
    '"tenant" database for ad hoc, throw-away tests, i.e. for play. '             ||e'\n';

  role_db$mgr_comment constant text not null := format(
    'Tenant role for the "%s" database for managing tenant roles there. '         ||e'\n'||
    'Owns no schema. Could own extra objects in the "mgr" schema  '               ||e'\n'||
    'than "template1" brings. Has "execute" on these procedures:  '               ||e'\n'||
    '"cr_role()", "drop_role". "mgr.set_role_password()".  '                      ||e'\n',
    db);

  role_db$developer_comment constant text not null := format(
    'Pure tenant role (cannot connect). Is the grantee for object privileges '    ||e'\n'||
    'that "developer" roles in the "%s" "tenant database" will need. '            ||e'\n',
    db);

  role_db$client_comment constant text not null := format(
    'Tenant role. Client-side code will authorize as this to connect to '         ||e'\n'||
    'the "%s" database. Owns no objects. Is the grantee for the '                 ||e'\n'||
    'designed set of object privileges that expose the client-facing API. '       ||e'\n',
    db);
begin
  assert current_role = 'clstr$mgr',
    'You must authorize as "current_role" to call "set_up_tenant_database()"';

  assert mgr.is_good_tenant_role_name(mgr_role),       'Bad tenant role name: '||mgr_role;
  assert mgr.is_good_tenant_role_name(developer_role), 'Bad tenant role name: '||developer_role;
  assert mgr.is_good_tenant_role_name(client_role),    'Bad tenant role name: '||client_role;

  /*
    These settings are not copied from "template1".
  */
  execute format($$alter database %I set client_min_messages   = 'warning';                             $$, db);
  execute format($$alter database %I set search_path = dt_utils, mgr, extensions, pg_catalog, pg_temp;  $$, db);
  execute format($$alter database %I set transaction_isolation = 'read committed';                      $$, db);

  call mgr.set_tenant_database_setting(db, 'log_error_verbosity', 'verbose');
  execute format($$revoke all on database %I from public;                          $$, db);
  execute format($$grant  all on database %I to clstr$mgr with grant option;       $$, db);

  declare
    db$mgr_exists boolean not null :=
      exists(select 1 from pg_roles where rolname = mgr_role);

    db$developer_exists boolean not null :=
      exists(select 1 from pg_roles where rolname = developer_role);

    db$client_exists boolean not null :=
      exists(select 1 from pg_roles where rolname = client_role);
  begin
    if db$mgr_exists then
      execute format('grant %I to clstr$mgr;',     mgr_role);
      execute format('drop owned by %I cascade;',  mgr_role);
      execute format('drop role %I;',              mgr_role);
    end if;

    if db$developer_exists then
      execute format('grant %I to clstr$mgr;',     developer_role);
      execute format('drop owned by %I cascade;',  developer_role);
      execute format('drop role %I;',              developer_role);
    end if;

    if db$client_exists then
      execute format('grant %I to clstr$mgr;',     client_role);
      execute format('drop owned by %I cascade;',  client_role);
      execute format('drop role %I;',              client_role);
    end if;
  end;

  --------------------------------------------------------------------------------------------------
  /*
    Create the <db>$developer role.

    This role is artificially granted "connect" on the present "tenant database" as a device
    to make it show up in mgr.tenant_roles" for this database.

    It can still be regarded as a "pure" role (i.e. not a so-called "user") because you cannot
    create a session by authorizing as this role.
  */
  execute format('
    create role %I with
      nocreatedb
      nocreaterole
      noinherit
      noreplication
      nobypassrls
      connection limit 0
      nologin password null;',
      developer_role);

  execute format('alter role %I set search_path = pg_catalog, pg_temp;',     developer_role);
  execute format('grant connect on database %I to %I;',                  db, developer_role);

  --------------------------------------------------------------------------------------------------
  -- Create the <db>mgr role.

  execute format('
    create role %I with
      nocreatedb
      nocreaterole
      noinherit
      noreplication
      nobypassrls
      connection limit -1
      in role %I
      login password ''m'';',
      mgr_role, developer_role);

  execute format('alter role %I set search_path = dt_utils, mgr, extensions, pg_catalog, pg_temp;',       mgr_role);
  execute format('grant all on database %I to %I;',                                                   db, mgr_role);
  execute format('grant execute on procedure mgr.drop_role(text) to %I;',                                 mgr_role);
  execute format('grant execute on procedure mgr.drop_all_regular_tenant_roles() to %I;',                 mgr_role);
  execute format('grant execute on procedure mgr.cr_role(text, boolean, boolean, boolean, text) to %I;',  mgr_role);
  execute format('grant execute on procedure mgr.set_role_path(text, text) to %I;',                       mgr_role);
  execute format('grant execute on procedure mgr.prepend_to_session_path(text) to %I;',                   mgr_role);
  execute format('grant execute on procedure mgr.set_role_password(text, text) to %I;',                   mgr_role);
  execute format('grant execute on procedure mgr.comment_on_current_db(text) to %I;',                     mgr_role);
  --------------------------------------------------------------------------------

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

  execute format('alter role %I set search_path = pg_catalog, pg_temp;',           client_role);
  execute format('grant connect on database %I to %I;',                        db, client_role);
  --------------------------------------------------------------------------------

  execute format('comment on database %I is %L',   db,             database_db_comment      );
  execute format('comment on role     %I is %L',   mgr_role,       role_db$mgr_comment      );
  execute format('comment on role     %I is %L',   developer_role, role_db$developer_comment);
  execute format('comment on role     %I is %L',   client_role,    role_db$client_comment   );
end;
$body$;

revoke all on procedure mgr.set_up_tenant_database() from public;
