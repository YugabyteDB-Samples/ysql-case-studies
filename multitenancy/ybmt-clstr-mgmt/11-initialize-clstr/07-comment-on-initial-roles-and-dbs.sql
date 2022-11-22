do $body$
declare
  database_template0_comment constant text not null :=
    'Shipped standard minimal template. '                                   ||e'\n'||
    'See the chapter "Template Databases" in the PG Doc. '                  ||e'\n'||
    'Intended as a fall-back. So MUST NOT MODIFY it. '                      ||e'\n';

  database_template1_comment constant text not null :=
    'Identical to "template0" immediately following "initdb". '             ||e'\n'||
    'Used by "create database" as its default template. '                   ||e'\n'||
    'Customized here to be the definition of the so-called '                ||e'\n'||
    '"tenant database" that supports YBMT "home-grown" multinenancy. '      ||e'\n';

  database_postgres_comment constant text not null :=
    '"Home base" for the "postgres" bootstrap superuser and for '           ||e'\n'||
    'the "clstr$mgr" databases and roles manager. '                         ||e'\n';

  role_postgres_comment constant text not null :=
    'Nominated at "initdb" time. Owner of "the system", i.e. the '          ||e'\n'||
    '"pg_catalog" schema, its contents, and similar in every database, '    ||e'\n'||
    'i.e. the so-called "bbotstrap superuser". '                            ||e'\n'||
    'Ensure that this is cluster''s ONLY superuser. '                       ||e'\n'||
    'It should not own any objects except for the "postgres" "home base" '  ||e'\n'||
    'database and a small few utility objects. '                            ||e'\n';

  role_clstr$mgr_comment constant text not null :=
    'Intended for managing databases and roles (ie global artifacts). '     ||e'\n'||
    'Owns the schema "mgr" and objects within this in "template1". '        ||e'\n';
begin
  /*
    Notice that "yb-ctl create" adds this comment for the "system_platform"
    database:
      "system database for YugaByte platform"
    Don't change it.
  */
  execute format('comment on database template0    is %L', database_template0_comment);
  execute format('comment on database template1    is %L', database_template1_comment);
  execute format('comment on database postgres     is %L', database_postgres_comment );
  execute format('comment on role     postgres     is %L', role_postgres_comment     );
  execute format('comment on role     clstr$mgr    is %L', role_clstr$mgr_comment    );
end;
$body$;
