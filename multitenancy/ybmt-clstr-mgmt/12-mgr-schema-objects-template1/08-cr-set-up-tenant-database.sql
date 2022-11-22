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


  /*
    TO_DO
    -----                         > dev_role
    Define constants for the mgr, developer, and client roles.
    Use new "good_db_name() to check ...
  */


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

  /*
    These settings are not copied from "template1".
  */
  execute format($$alter database %I set client_min_messages   = 'warning';        $$, db);
  execute format($$alter database %I set transaction_isolation = 'read committed'; $$, db);
  call mgr.set_tenant_database_setting(db, 'log_error_verbosity', 'verbose');
  execute format($$revoke all on database %I from public;                          $$, db);
  execute format($$grant  all on database %I to clstr$mgr with grant option;       $$, db);

  declare
    db$mgr_exists boolean not null :=
      exists(select 1 from pg_roles where rolname = db||'$mgr');

    db$developer_exists boolean not null :=
      exists(select 1 from pg_roles where rolname = db||'$developer');

    db$client_exists boolean not null :=
      exists(select 1 from pg_roles where rolname = db||'$client');
  begin
    if db$mgr_exists then
      execute format('grant %I to clstr$mgr;',     db||'$mgr');
      execute format('drop owned by %I cascade;',  db||'$mgr');
      execute format('drop role %I;',              db||'$mgr');
    end if;

    if db$developer_exists then
      execute format('grant %I to clstr$mgr;',     db||'$developer');
      execute format('drop owned by %I cascade;',  db||'$developer');
      execute format('drop role %I;',              db||'$developer');
    end if;

    if db$client_exists then
      execute format('grant %I to clstr$mgr;',     db||'$client');
      execute format('drop owned by %I cascade;',  db||'$client');
      execute format('drop role %I;',              db||'$client');
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
      db||'$developer');

  execute format('alter role %I set search_path = pg_catalog, pg_temp;',     db||'$developer');
  execute format('grant connect on database %I to %I;',                  db, db||'$developer');

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
      db||'$mgr', db||'$developer');

  execute format('alter role %I set search_path = mgr, pg_catalog, pg_temp;',                             db||'$mgr');
  execute format('grant all on database %I to %I;',                                                   db, db||'$mgr');
  execute format('grant execute on procedure mgr.drop_role(text) to %I;',                                 db||'$mgr');
  execute format('grant execute on procedure mgr.drop_all_regular_tenant_roles() to %I;',                 db||'$mgr');
  execute format('grant execute on procedure mgr.cr_role(text, boolean, boolean, boolean, text) to %I;',  db||'$mgr');
  execute format('grant execute on procedure mgr.set_role_path(text, text) to %I;',                       db||'$mgr');
  execute format('grant execute on procedure mgr.set_role_password(text, text) to %I;',                   db||'$mgr');

  execute format('grant execute on procedure mgr.comment_on_current_db(text) to %I;',                     db||'$mgr');
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
      db||'$client');

  execute format('alter role %I set search_path = mgr, pg_catalog, pg_temp;',      db||'$client');
  execute format('grant connect on database %I to %I;',                        db, db||'$client');
  --------------------------------------------------------------------------------

  execute format('comment on database %I is %L',   db,               database_db_comment      );
  execute format('comment on role     %I is %L',   db||'$mgr',       role_db$mgr_comment      );
  execute format('comment on role     %I is %L',   db||'$developer', role_db$developer_comment);
  execute format('comment on role     %I is %L',   db||'$client',    role_db$client_comment   );
end;
$body$;

revoke all on procedure mgr.set_up_tenant_database() from public;
