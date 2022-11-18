/*
  Notice this wording from "5.7. Privileges",
  https://www.postgresql.org/docs/15/ddl-priv.html

  PostgreSQL grants privileges on some types of objects to PUBLIC by default when the objects are created...
  For other types of objects, the default privileges granted to PUBLIC are as follows:
  CONNECT and TEMPORARY... privileges for databases...

  Similar wording is buried somewhere in the Version 11 doc.

  There's a little catch. Normally, "pg_database.datacl" lists all the privileges on
  a database to every role that has these. However, "datacl" for a newly created database
  that hasn't yet been the object of "grant" or revoke" is NULL. This has a different representation,
  for the meaning "{=Tc/grantor_role}".

  This is why the predicate "datacl is null" is included in the definition of the "bad_dbs" list.
*/;
create procedure mgr.assert_no_db_has_privs_granted_to_public()
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  bad_dbs constant name[] :=(
      select array_agg(datname)
      from pg_database
      where has_database_privilege('public', datname, 'connect')
      or    has_database_privilege('public', datname, 'create')
      or    has_database_privilege('public', datname, 'temp')

      /*
        Compare with this alternative formulation of the "where" clause:

        where datacl is null
        or    0::oid = any(select (aclexplode(datacl)).grantee)
      */
    );
begin
  assert (bad_dbs is null or cardinality(bad_dbs) = 0),
    'databases found with privs granted to public:'||e'\n'||bad_dbs::text;
end;
$body$;
revoke all on procedure mgr.assert_no_db_has_privs_granted_to_public() from public;
