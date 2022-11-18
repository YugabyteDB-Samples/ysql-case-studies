create view mgr.reserved_roles(name) as
select rolname
from pg_roles
where rolname ~ '^pg_'
or    rolname ~ '^yb_'
or    rolname = 'postgres'
or    rolname = 'yugabyte'
or    rolname ~ '^clstr\$';

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

create function mgr.is_good_db_name(proposed_name in text)
  returns boolean
  immutable
  security definer
  language plpgsql
as $body$
begin
  /*
    Enforce the naming convention for this cluster.
    A tenant database name must start with "d" and must be followed by only digits
    as created using « 'd'||n::text » where "n" is an integer. Therefore, with the
    exception of the name "d0", the first character after the "d" must not be zero.
  */
  if length(proposed_name) < 1 then
    return false;
  else
    declare
      char_1 constant text := substr(proposed_name, 1, 1);
      suffix constant text := substr(proposed_name, 2, length(proposed_name));
    begin
      if char_1 != 'd' then
        return false;
      else
        begin
          declare
            suffix_as_int constant int not null := suffix::int;
            typecast_suffix constant text not null := suffix_as_int::text;
          begin
            return typecast_suffix = suffix;
          end;
        exception when invalid_text_representation then
          return false;        
        end;
      end if;
    end;
  end if;
end;
$body$;

grant execute on function mgr.is_good_db_name(text) to public;
--------------------------------------------------------------------------------

create function mgr.is_good_role_nickname(proposed_name in text)
  returns boolean
  immutable
  security definer
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
    in "mgr.good_role_nickname()" below.

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

grant execute on function mgr.is_good_role_nickname(text) to public;
--------------------------------------------------------------------------------

create function mgr.good_role_nickname(proposed_name in text)
  returns text
  immutable
  security definer
  language plpgsql
as $body$
declare
  good constant boolean not null := mgr.is_good_role_nickname(proposed_name);

  code constant text    not null := '42602'; -- invalid_name
  msg  constant text    not null :=
    e'\n'||
    '        Bad <role-nickname>: "'||proposed_name||'".'                               ||e'\n'||
    '        A <role-nickname> must contain only lower case ASCII(7) letters, '         ||e'\n'||
    '        digits, or underscores and must not start with a digit or an underscore '  ||e'\n';
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

grant execute on function mgr.good_role_nickname(text) to public;
--------------------------------------------------------------------------------

create function mgr.tenant_role_name(role_nickname in text)
  returns text
  immutable
  security definer
  language plpgsql
as $body$
begin
  /*
    Sanity check. The "create database" proc should have ensured that the db name is good.
  */
  assert mgr.is_good_db_name(current_database()::text),
    'Bad tenent database name '||current_database()::text;

  declare
    good_role_nickname constant text not null := mgr.good_role_nickname(role_nickname);
  begin
    return (current_database()::text||'$'||good_role_nickname);
  end;
end;
$body$;

grant execute on function mgr.tenant_role_name(text) to public;
--------------------------------------------------------------------------------

create function mgr.is_good_tenant_role_name(role_name in name)
  returns boolean
  immutable
  security definer
  language plpgsql
as $body$
declare
  t              text   not null := '';
  parts constant text[] not null := regexp_split_to_array(role_name::text, '\$');
begin
  if cardinality(parts) != 2 then
    return false;
  elsif (not mgr.is_good_db_name(parts[1])) or (not mgr.is_good_role_nickname(parts[2])) then
    return false;
  else
    return true;
  end if;
end;
$body$;

grant execute on function mgr.is_good_tenant_role_name(name) to public;
