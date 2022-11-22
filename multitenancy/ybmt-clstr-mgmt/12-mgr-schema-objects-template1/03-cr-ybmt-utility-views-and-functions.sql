create view mgr.reserved_roles(name) as
select rolname
from pg_roles
where rolname ~ '^pg_'
or    rolname ~ '^yb_'
or    rolname = 'postgres'
or    rolname = 'yugabyte'
or    rolname = 'clstr$mgr';

grant select on table mgr.reserved_roles to public;
--------------------------------------------------------------------------------

create view mgr.non_reserved_roles(oid, name) as
select oid, rolname
from pg_roles r
where not exists
  (
    select 1 from mgr.reserved_roles a
    where a.name = r.rolname
  );

grant select on table mgr.non_reserved_roles to public;
--------------------------------------------------------------------------------

create function mgr.is_good_name(proposed_name in text)
  returns boolean
  immutable
  security invoker
  language plpgsql
as $body$
declare
  /*
    Enforce the naming convention for this cluster. Apart from the roles
    that the view "mgr.reserved_roles" lists, all other roles will be
    so-called "tenant roles" (i.e. able to connect to exactly one tenant database).
    The names of tenant roles will follow this convention.

      <database-name>$<role-nickname>

    Both <database-name> and <role-nickname> must be "good". See the text of "msg"
    in "mgr.good_name()" below.

    The implementation uses regular expressions.
    See, for example:

      en.wikipedia.org/wiki/Regular_expression
      www3.ntu.edu.sg/home/ehchua/programming/howto/Regexe.html

      ^    :: Matches the starting position within the string.

      [^ ] :: Matches a single character that is not contained within the brackets.
      For example, [^a-z] matches any single character that is not a lowercase
      letter from "a" through "z". 
  */

begin
  if length(proposed_name) < 1 then
    return false;
  else
    declare
      -- Remove all characters except lower-case Latin letters, digits, and underscores.
      n1 constant text not null := regexp_replace(proposed_name, '[^a-z0-9_]', '', 'g');

      -- Remove any digit or underscore in just the first postion.
      n2 constant text not null := regexp_replace(n1, '^[0-9_]', '');
    begin
      case n1 = proposed_name
        when false then
          -- Rule 1 violated: bad characters found.
          return false;
        else
          case n2 = n1
            when false then
              -- Rule 2 violated: starts with digit or underscore.
              return false;
            else
              return true;
          end case;
      end case;
    end;
  end if;
end;
$body$;

grant execute on function mgr.is_good_name(text) to public;
--------------------------------------------------------------------------------

create function mgr.good_name(proposed_name in text)
  returns text
  immutable
  security invoker
  language plpgsql
as $body$
declare
  good constant boolean not null := mgr.is_good_name(proposed_name);

  code constant text    not null := '42602'; -- invalid_name
  msg  constant text    not null :=
    e'\n'||
    '        <database-name> or <role-nickname> for tenant is bad.'                                        ||e'\n'||
    '        (The name of a tenant role is formed as <database-name>$<role-nickname>.) '                   ||e'\n'||
    '        A <database-name> and a <role-nickname> must each contain only lower case ASCII(7) letters, ' ||e'\n'||
    '        digits, or underscores and must not start with a digit or an underscore '                     ;
begin
  case good
    when false then
      raise exception using
        message = msg,
        errcode = code;
    else
      return proposed_name;
  end case;
end;
$body$;

grant execute on function mgr.good_name(text) to public;
--------------------------------------------------------------------------------

create function mgr.tenant_role_name(role_nickname in text)
  returns text
  immutable
  security invoker
  language plpgsql
as $body$
declare
  /*
    Sanity check. The "create database" proc will have ensured that the db name is good.
  */
  good_db_name       constant text not null := mgr.good_name(current_database()::text);
  good_role_nickname constant text not null := mgr.good_name(role_nickname);

begin
  return (good_db_name||'$'||good_role_nickname);
end;
$body$;

grant execute on function mgr.tenant_role_name(text) to public;
--------------------------------------------------------------------------------

create function mgr.is_good_tenant_role_name(role_name in name)
  returns boolean
  immutable
  security invoker
  language plpgsql
as $body$
declare
  t              text   not null := '';
  parts constant text[] not null := regexp_split_to_array(role_name::text, '\$');
begin
  if cardinality(parts) != 2 then
    return false;
  elsif (not mgr.is_good_name(parts[1])) or (not mgr.is_good_name(parts[2])) then
    return false;
  else
    return true;
  end if;
end;
$body$;

grant execute on function mgr.is_good_tenant_role_name(name) to public;
--------------------------------------------------------------------------------
/*
  Notice that the "pure" (not "user") role <db>$developer is artificially
  granted "connect" on the tennant database for which it is defined to establish
  its status as a "tenant role" for that database.

  As long as a role that is not listed in "mgr.reserved_roles" is created by
  calling "mgr.cr_role()", and never by direct user of the "create role" DDL,
  then all the roles that "mgr.tenant_roles" will have well formed names
  the follow the "<database-name>$<role-nickname>" pattern.

  Notice that the ONLY roles with "rolcanlogin" that are able to execute
  "create role" explicitly are "postgres" and "clstr$mgr".
*/;
create view mgr.tenant_roles(name, comment) as
with
  roles_with_comments(name, comment) as (
    select r.name, c.description
    from
      non_reserved_roles r
      inner join pg_shdescription c
      on r.oid = c.objoid
    where  c.classoid = 1260),

  role_with_connect_on_database_pairs(r_name, d_name, comment) as (
      select
        r.name, d.datname, r.comment
      from
        roles_with_comments r
        cross join
        pg_database d
      where has_database_privilege(r.name, d.datname, 'connect')
    )
select r_name, comment
from role_with_connect_on_database_pairs
where  d_name = current_database()           -- Roles that can connect here.

except

select r_name, comment
from role_with_connect_on_database_pairs
where d_name != current_database();         -- Roles that can connect elsewhere and maybe here too

grant select on table mgr.tenant_roles to public;
--------------------------------------------------------------------------------

create type mgr.rolname_and_comment as(r_name name, r_comment text);

create function mgr.roles_with_comments()
  returns table(z text)
  stable
  security invoker
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  tr mgr.rolname_and_comment not null := (''::name, ''::text)::mgr.rolname_and_comment;
  local_roles constant mgr.rolname_and_comment[] := (
    select array_agg((r.name, r.comment)::mgr.rolname_and_comment order by r.name) from mgr.tenant_roles r);

  global_roles constant mgr.rolname_and_comment[] := (
    select array_agg((r.rolname, c.description)::mgr.rolname_and_comment order by r.rolname)
    from
      pg_roles r
      inner join pg_shdescription c
      on r.oid = c.objoid
    where c.classoid = 1260
    and r.rolname in ('postgres', 'clstr$mgr'));

  c_lines text[] not null := '{}'::text[];
begin
  if local_roles is not null and cardinality(local_roles) > 0 then
    foreach tr in array local_roles loop
      c_lines := string_to_array(tr.r_comment, e'\n');

      for j in array_lower(c_lines, 1)..array_upper(c_lines, 1) loop
        case j
          when 1 then
            z := rpad(tr.r_name, 20)||c_lines[j];                   return next;
          else
            z := rpad(' ',       20)||c_lines[j];                   return next;
        end case;
      end loop;
    end loop;
  end if;

  foreach tr in array global_roles loop
    c_lines := string_to_array(tr.r_comment, e'\n');

    for j in array_lower(c_lines, 1)..array_upper(c_lines, 1) loop
      case j
        when 1 then
          z := rpad(tr.r_name, 20)||c_lines[j];                     return next;
        else
          z := rpad(' ',       20)||c_lines[j];                     return next;
      end case;
    end loop;
  end loop;
end;
$body$;

grant execute on function mgr.roles_with_comments() to public;
--------------------------------------------------------------------------------

drop function if exists mgr.dbs_with_comments() cascade;

create function mgr.dbs_with_comments()
  returns table(z text)
  stable
  security invoker
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  db_name   name not null := ''::name;
  db_owner  name not null := ''::name;
  comment   text not null := '';

  c_lines text[] not null := '{}'::text[];
begin
  for db_name, db_owner, comment in (
    select d.datname, r.rolname, c.description
    from
      pg_database d
      inner join
      pg_roles r
      on d.datdba = r.oid
      inner join pg_shdescription c
      on d.oid = c.objoid
    where c.classoid = 1262
    order by d.datname)
  loop
    c_lines := string_to_array(comment, e'\n');

    for j in array_lower(c_lines, 1)..array_upper(c_lines, 1) loop
      case j
        when 1 then
          z := rpad(db_name, 20)||rpad(db_owner, 20)||c_lines[j];             return next;
        else
          z := rpad(' ',       40)                        ||c_lines[j];       return next;
      end case;
    end loop;
  end loop;
end;
$body$;

grant execute on function mgr.dbs_with_comments() to public;
