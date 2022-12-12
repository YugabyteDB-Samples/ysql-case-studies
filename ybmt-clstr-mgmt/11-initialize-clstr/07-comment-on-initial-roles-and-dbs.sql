do $body$
declare
  database_template0_comment constant text not null :=
    'Shipped standard minimal template. '                                     ||e'\n'||
    'See the chapter "Template Databases" in the PG Doc. '                    ||e'\n'||
    'Intended as a fall-back. So MUST NOT MODIFY it. '                        ||e'\n';

  database_template1_comment constant text not null :=
    'Identical to "template0" immediately following "initdb". Used by '       ||e'\n'||
    '"create database" as its default template. Customized here to be '       ||e'\n'||
    'the definition of the so-called "tenant database"'                       ||e'\n'||
    'that supports YBMT multinenancy by convention. '                         ||e'\n';

  -- "yb-ctl create" produces the old
  -- "system database for YugaByte platform" spelling.
  database_system_platform_comment constant text not null :=
    'System database for "YugabyteDB Anywhere". '                             ||e'\n';

  database_yugbyte_comment constant text not null :=
    '"Home base" for the "yugabyte" superuser and for '                       ||e'\n'||
    'the "clstr$mgr" databases and roles manager. '                           ||e'\n';

  role_postgres_comment constant text not null :=
    'Nominated at "initdb" time. Owner of "the system", i.e. the '            ||e'\n'||
    '"pg_catalog" schema, its contents, and similar in every database, '      ||e'\n'||
    'i.e. the so-called "bootstrap superuser". '                              ||e'\n'||
    'It should not own any objects except for the PostgreSQL system '         ||e'\n'||
    'Its password is set to NULL. Don''t use this to start a session; '       ||e'\n';

  role_yugabyte_comment constant text not null :=
    'The "ordinary" superuser for occasional tasks that need this power. '    ||e'\n';

  role_clstr$mgr_comment constant text not null :=
    'The "cluster manager". Non-superuser with "createdb" and "createrole". ' ||e'\n'||
    'Owns the "security definer" subprograms in the "mgr" schema for  '       ||e'\n'||
    'provisioning tenant databases and their local roles. '                   ||e'\n';
begin
  /*
    Notice that "yb-ctl create" adds this comment for the "system_platform"
    database:
      "system database for YugaByte platform"
    Don't change it.
  */
  execute format('comment on database template0          is %L', database_template0_comment);
  execute format('comment on database template1          is %L', database_template1_comment);

  if version() like '%YB%' then
    execute format('comment on database system_platform  is %L', database_system_platform_comment );
  end if;

  execute format('comment on database yugabyte           is %L', database_yugbyte_comment );
  execute format('comment on role     postgres           is %L', role_postgres_comment     );
  execute format('comment on role     yugabyte           is %L', role_yugabyte_comment     );
  execute format('comment on role     clstr$mgr          is %L', role_clstr$mgr_comment    );
end;
$body$;
