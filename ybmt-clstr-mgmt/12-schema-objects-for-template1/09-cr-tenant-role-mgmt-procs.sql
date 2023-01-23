/*
  The exposed API procedures, "drop_role()", "cr_role()", and "set_role_password()",
  reject bad values for the "nickname" formal.

  Use the term "tenant role" to mean a non-superuser role that can connect ONLY
  to "current_database()"

  The view "tenant_roles" and all of the subprograms the this script file creates
  will be installed in the "mgr" schema in the "template1" database and will
  be owned by "clstr$mgr".

  Two exceptions. These "security definer" procedures must be owner by a superuser:
    mgr.set_tenant_database_setting(db in text, setting in text, val in text)
    mgr.drop_all_temp_schemas()
*/;
do $body$
begin
  assert current_database() = 'template1',  'must do this in the "template1" database';
  assert current_role       = 'clstr$mgr',  'must do this as the "clstr$mgr" role';
end;
$body$;
--------------------------------------------------------------------------------
/*
  Reliable only on single-node YB (and on PG, of course).

  See the comment in:
    ../13-mgr-schema-objects-postgres-db-only/01-kill-all-sessions-for-specified-database.sql
*/
create procedure mgr.kill_all_sessions_for_role(r_name in name)
  security definer
  set client_min_messages = warning
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  p int not null := 0;
  pids constant int[] :=
    (
      select array_agg(pid)
      from pg_stat_activity
      where pid          != pg_backend_pid()
      and   backend_type =  'client backend'
      and usename        =  r_name
    );
begin
  if (pids is not null and cardinality(pids) > 0) then
    foreach p in array pids loop
      perform pg_terminate_backend(p);
    end loop;
  end if;
end;
$body$;
revoke all on procedure mgr.kill_all_sessions_for_role(name) from public;
--------------------------------------------------------------------------------
/*
  The logic here could be simplified by relying on the naming convention
  for a tenant role: <db-name>.<role-nickname>. Doing this would
  renove the need to compute, and test, the boolean constants
  "can_connect_here" and "can_connect_elsewhere".

  But using the present logic acts as a useful self-check that the
  conventions of the "YBMT" multitenancy scheme are not broken.

  Further, the two separate tests on "can_connect_here" and "can_connect_elsewhere"
  could be replace by a simpler test that candinate "r_name" role is found in
  the "tenant_roles" view. The definition of that view uses the same logic that
  defines these two boolean constants. But the present allows more informative
  error messages to be issued if the conventions are broken.
*/;
create function mgr.is_regular_tenant_role(
  r_name         in  name,
  allow_client   in boolean,
  reserved_name  out boolean,
  name_exists    out boolean,
  ok             out boolean,
  code           out text,
  message        out text)
  returns  record
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  this_database            constant text not null := current_database()::text;
  this_database_mgr        constant text not null := mgr.tenant_role_name('mgr');
  this_database_developer  constant text not null := mgr.tenant_role_name('developer');
  this_database_client     constant text not null := mgr.tenant_role_name('client');
  this_database_msg        constant text not null := 'database "'||this_database||'"';

  is_super constant boolean not null :=
    exists (select 1 from pg_roles where rolname = r_name and rolsuper);

  can_connect_here constant boolean not null :=
    exists
      (
        select 1 from pg_roles r cross join pg_database d
        where d.datname = current_database()
        and r.rolname = r_name
        and has_database_privilege(r.rolname, d.datname, 'connect')
      );

  can_connect_elsewhere constant boolean not null :=
    exists
      (
        select 1 from pg_roles r cross join pg_database d
        where d.datname != current_database()
        and r.rolname = r_name
        and has_database_privilege(r.rolname, d.datname, 'connect')
      );
begin
  reserved_name :=
    /*
      See Issue #13833. PG prevents you from creating a role with "rolname ~ '^pg_'"
      But YB has no such rule for creating a role with "rolname ~ '^yb_'".
      Therefore implement that rule here and in "cr_role()". Keep it symmetrical
      for PG and for YB.
    */
    r_name::text = 'postgres'              or
    r_name::text = 'yugabyte'              or
    r_name::text = 'clstr$mgr'             or
    r_name::text = this_database_mgr       or
    r_name::text = this_database_developer or
    r_name::text ~ '^pg_'                  or
    r_name::text ~ '^yb_'                  ;

  if not allow_client then
    reserved_name := reserved_name or r_name::text = this_database_client;
  end if;

  name_exists :=
    (select exists
      (select 1 from pg_roles where rolname = r_name)
    );

  -- '42704' is mapped to "undefined_object".
  -- '42501' is mapped to "insufficient_privilege".
  case
    when reserved_name then
      ok            := false;
      code          := '42939';
      message := 'Role names "postgres", "yugabyte", "clstr$mgr", '||
                  '"'||this_database_mgr||'", "'||this_database_developer||'", "'||this_database_client||'", '||
                  'and starting with "pg_" or "yb_" are reserved.';
      return;

    when not name_exists then
      ok := true;
      code := '42704';
      message := 'Role "'||r_name::text||'" does not exist';
      return;

    when is_super then
      ok := false;
      code :=   '42501';
      message := 'Role "'||r_name::text||'" is a superuser';
      return;

    when not can_connect_here then
      ok := false;
      code :=   '42501';
      message := 'Role "'||r_name::text||'" cannot connect to '||this_database_msg;
      return;

    when can_connect_elsewhere then
      ok := false;
      code :=   '42501';
      message := '"'||r_name::text||'" is not tenant role for '||this_database_msg;
      return;

    else
      ok := true;
      code := null;
      message := null;
      return;
  end case;
end;
$body$;
revoke all on function mgr.is_regular_tenant_role(name, boolean) from public;
--------------------------------------------------------------------------------

create function mgr.is_reserved(r_name in name)
  returns boolean
  security definer
  set client_min_messages = warning
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  v_reserved_name           boolean not null := false;
  v_name_exists             boolean not null := false;
  v_ok                      boolean not null := false;
  v_code                    text;
  v_message                 text;
begin
  select   reserved_name,   name_exists,   ok,   code,   message
  into   v_reserved_name, v_name_exists, v_ok, v_code, v_message
  from mgr.is_regular_tenant_role(r_name, false);

  return v_reserved_name;
end;
$body$;
revoke all on function mgr.is_reserved(name) from public;
--------------------------------------------------------------------------------

create procedure mgr.drop_role(nickname in text)
  security definer
  set client_min_messages = warning
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  r_name           constant name    not null := mgr.tenant_role_name(nickname);
  v_reserved_name           boolean not null := false;
  v_name_exists             boolean not null := false;
  v_ok                      boolean not null := false;
  v_code                    text;
  v_message                 text;
begin
  select   reserved_name,   name_exists,   ok,   code,   message
  into   v_reserved_name, v_name_exists, v_ok, v_code, v_message
  from mgr.is_regular_tenant_role(r_name, false);

  case
    when v_reserved_name or (v_name_exists and not v_ok) then
      raise exception using
        message = v_message,
        errcode = v_code;

    else
      if v_name_exists then
        /*
          Without this "drop owned by" will hang indefinitely,
          if the role 'r_name' has an in-flight txn, waiting for it
          to commit or roll back.
        */
        execute format('alter role %I connection limit 0', r_name::text);
        call mgr.kill_all_sessions_for_role(r_name);

        /*
          Needed when the owner of "cr_role()" is a non-superuser that has just "rolcreaterole" set to "true".
          If "r" is not granted to "clstr$mgr", then "drop owned by r" fails with the error
          42501: permission denied to drop objects.

          Moreover, if "r" has any object privileges, on objects owned by other roles (esp. a schema), then
          "drop owned by r" fails with "no privileges could be revoked for <the object>".

          The fix is to grant EVERY to-be-dropped tenant role to "clstr$mgr" and to revoke when done.
        */
        declare
          n name not null := '';
          names name[] := (
              select array_agg(name) from mgr.tenant_roles
              where not mgr.is_reserved(name)
            );
        begin
          if (names is not null and cardinality(names) > 0) then
            foreach n in array names loop
              execute format('grant %I to clstr$mgr', n);
            end loop;
          end if;
        end;

        execute format('drop owned by %I cascade', r_name::text);
        execute format('drop role %I', r_name::text);

        declare
          n name not null := '';
          names name[] := (
              select array_agg(name) from mgr.tenant_roles
              where not mgr.is_reserved(name)
            );
        begin
          if (names is not null and cardinality(names) > 0) then
            foreach n in array names loop
              execute format('revoke %I from clstr$mgr', n);
            end loop;
          end if;
        end;
      end if;
  end case;
end;
$body$;
revoke all on procedure mgr.drop_role(text) from public;
--------------------------------------------------------------------------------

create procedure mgr.cr_role(
  nickname         in text,
  with_schema      in boolean = true,
  with_temp_on_db  in boolean = false,
  comment          in text    = 'For ad hoc tests')
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  -- Asserts that "nickname" follows the convention for the "YBMT" multitenancy cluster.
  r_name             constant name not null := mgr.tenant_role_name(nickname);
  this_database_mgr  constant text not null := mgr.tenant_role_name('mgr');
begin
  call mgr.drop_role(nickname);

  execute format(
    'create role %I with '||
    'inherit nosuperuser nocreaterole nocreatedb noreplication nobypassrls '||
    'in role clstr$developer '                                              ||
    'connection limit 0 nologin password null',                             r_name::text);

  -- Set a sensible default. Notice that procedure "set_role_search_path()" lets you change it.
  execute format('alter role %I set search_path = client_safe, dt_utils, mgr, extensions, pg_catalog, pg_temp', r_name::text);

  execute format('grant connect on database %I to %I', current_database(),  r_name::text);
  execute format('grant create  on database %I to %I', current_database(),  r_name::text);
  execute format('grant %I to %I',                                          r_name::text, this_database_mgr);

  if with_schema then
    /*
      "grant %I to clstr$mgr" is needed when the owner of "cr_role()" is a non-superuser that
      has just "rolcreaterole" set to "true". If "r" is not granted to "clstr$mgr", then
      "create schema s authorization r" fails with the error 42501: must be member of role "r"
    */
    execute format('grant %I to clstr$mgr', r_name::text);
    execute format('create schema %I authorization %I', nickname, r_name);
    execute format('revoke all on schema %I from public', nickname);

    -- Notice that we can now revoke the role in question from "clstr$mgr".
    execute format('revoke %I from clstr$mgr', r_name::text);
  end if;

  if with_temp_on_db then
    execute format('grant temporary on database %I to %I', current_database(), r_name::text);
  end if;

  execute format('comment on role %I is %L', r_name::text, comment||e'\n');
end;
$body$;
revoke all on procedure mgr.cr_role(text, boolean, boolean, text) from public;
--------------------------------------------------------------------------------

create procedure mgr.set_role_search_path(nickname in text, path in text)
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  r_name           constant name    not null := mgr.tenant_role_name(nickname);
  v_reserved_name           boolean not null := false;
  v_name_exists             boolean not null := false;
  v_ok                      boolean not null := false;
  v_code                    text;
  v_message                 text;
begin
  select   reserved_name,   name_exists,   ok,   code,   message
  into   v_reserved_name, v_name_exists, v_ok, v_code, v_message
  from mgr.is_regular_tenant_role(r_name, true);

  case
    when not (v_name_exists and v_ok) then
      raise exception using
        message = v_message,
        errcode = v_code;
    else
      execute format('alter role %I set search_path = %s', r_name::text, path);
  end case;
end;
$body$;
revoke all     on procedure mgr.set_role_search_path(text, text) from public;
grant  execute on procedure mgr.set_role_search_path(text, text) to   clstr$developer;
--------------------------------------------------------------------------------

/*
  This must be a "security invoker" procedure so that "current_setting('search_path')"
  sees that value that it needs to.
*/;
create procedure mgr.prepend_to_current_search_path(p in text)
  security invoker
  language plpgsql
as $body$
declare
  curr_path constant text not null := current_setting('search_path');
begin
  execute format ('set search_path = %s', p||', '||curr_path);
end;
$body$;
revoke all     on procedure mgr.prepend_to_current_search_path(text) from public;
grant  execute on procedure mgr.prepend_to_current_search_path(text) to   clstr$developer;
--------------------------------------------------------------------------------

create procedure mgr.set_role_password(nickname in text, password in text)
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  r_name           constant name    not null := mgr.tenant_role_name(nickname);
  v_reserved_name           boolean not null := false;
  v_name_exists             boolean not null := false;
  v_ok                      boolean not null := false;
  v_code                    text;
  v_message                 text;
begin
  select   reserved_name,   name_exists,   ok,   code,   message
  into   v_reserved_name, v_name_exists, v_ok, v_code, v_message
  from mgr.is_regular_tenant_role(r_name, true);

  case
    when not (v_name_exists and v_ok) then
      raise exception using
        message = v_message,
        errcode = v_code;
    else
      execute format('alter role %I with connection limit -1 login password %L', r_name::text, password);
  end case;
end;
$body$;
revoke all     on procedure mgr.set_role_password(text, text) from public;
grant  execute on procedure mgr.set_role_password(text, text) to  clstr$developer;
--------------------------------------------------------------------------------
/*
  This must be "security invoker", else error 42501:
  cannot set parameter "role" within security-definer function
*/;
create procedure mgr.set_role(nickname in text)
  security invoker
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  r_name constant text not null := mgr.tenant_role_name(nickname)::text;
begin
  execute format('set role %I', r_name);
end;
$body$;
revoke all     on procedure mgr.set_role(text) from public;
grant  execute on procedure mgr.set_role(text) to   clstr$developer;
--------------------------------------------------------------------------------

/*
  Using "revoke_all_from_public()" rather than using the bare "revoke" statement in explicit SQL,
  avoids the need to use the real role name. (The real name starts with the name of the database.)

  This procedure encapsulates the use of "tenant_role_name()", which in turn
  enclusulates "current_database()", so that the calling code doesn't need to mention the
  database name. This majes such code easier to deploy in any suitable tenant databse.

  The owning "clstr$mgr" role (unlike one "with superuser") cannot revoke an
  arbitrary privilege from an arbitrary role. So it's appropriate to make this
  "security invoker" so that it will succeed, or not, according to the invoker's
  ability to revoke the specified privilege.
*/;
create procedure mgr.revoke_all_from_public(
  object_kind  in text,
  object       in text)
  security invoker
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  kind   constant text not null := case
                                     when lower(object_kind) = 'view' then 'table'
                                     else                                   object_kind
                                   end;
begin
  execute format('revoke all on %s %s from public', kind, object);
end;
$body$;
revoke all     on procedure mgr.revoke_all_from_public(text, text) from public;
grant  execute on procedure mgr.revoke_all_from_public(text, text) to   clstr$developer;
--------------------------------------------------------------------------------

/*
  Using "grant_priv()" rather than using the bare "grant" statement in explicit SQL,
  avoids the need to use the real role name. (The real name starts with the name of the database.)

  This procedure encapsulates the use of "tenant_role_name()", which in turn
  enclusulates "current_database()", so that the calling code doesn't need to mention the
  database name. This majes such code easier to deploy in any suitable tenant databse.

  The owning "clstr$mgr" role (unlike one "with superuser") cannot grant an
  arbitrary privilege to an arbitrary role. So it's appropriate to make this
  "security invoker" so that it will succeed, or not, according to the invoker's
  ability to grant the specified privilege.
*/;
create procedure mgr.grant_priv(
  priv              in text,
  object_kind       in text,
  object            in text,
  grantee_nickname  in text)
  security invoker
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  kind   constant text not null := case
                                     when lower(object_kind) = 'view' then 'table'
                                     else                                   object_kind
                                   end;
  r_name constant text not null := case
                                     when grantee_nickname = 'public' then 'public'
                                     else mgr.tenant_role_name(grantee_nickname)::text
                                   end;
begin
  execute format('grant %s on %s %s to %I', priv, kind, object, r_name);
end;
$body$;
revoke all     on procedure mgr.grant_priv(text, text, text, text) from public;
grant  execute on procedure mgr.grant_priv(text, text, text, text) to   clstr$developer;
--------------------------------------------------------------------------------

create procedure mgr.drop_all_regular_local_roles()
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  this_database_mgr        constant text not null := mgr.tenant_role_name('mgr');
  this_database_client     constant text not null := mgr.tenant_role_name('client');

  r name not null := '';
  roles_to_be_dropped constant name[] := (
      select array_agg(name order by name)
      from mgr.tenant_roles
      where name <> this_database_mgr
      and   name <> this_database_client
    );
begin
  -- Routine hygiene.
  call mgr.drop_all_temp_schemas();

  if (roles_to_be_dropped is not null and cardinality(roles_to_be_dropped) > 0) then
    foreach r in array roles_to_be_dropped loop
      /*
        "drop_role()" is designed to prefix the "nickname" argument with
        the name of the current database and then the dollar-sign separator.
        So the prefix must be stripped off here so that "drop_role()" can put it back!
      */
      call mgr.drop_role(regexp_replace(r::text, '^'||current_database()::text||'\$', ''));
    end loop;
  end if;
end;
$body$;
revoke all on procedure mgr.drop_all_regular_local_roles() from public;
----------------------------------------------------------------------------------------------------

create procedure mgr.comment_on_current_db(comment in text)
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
begin
  execute format('comment on database %I is %L', current_database()::text, comment||e'\n');
end;
$body$;

revoke all on procedure mgr.comment_on_current_db(text) from public;
