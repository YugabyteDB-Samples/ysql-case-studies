create function mgr.create_tenant_databases_script(
  filename     in text,
  lower_db_no  in int,
  upper_db_no  in int)
  returns table(z text)
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  d       text not null := 'd';
  db_name text not null := '';
begin
  for j in lower_db_no..upper_db_no loop
    db_name := d||j::text;
    z :=        $$  \c postgres clstr$mgr                $$;            return next;
    z := format($$  create database %I owner clstr$mgr;  $$,  db_name); return next;
    z := format($$  \c %I clstr$mgr                      $$,  db_name); return next;
    z := format($$  call mgr.set_up_tenant_database();   $$);           return next;
  end loop;

  -- Have this script remove itself when it has been executed.
  -- "rm -Rf" suppresses error messages when nothing to delete.
  z := format('\! rm -Rf %s', filename);                                   return next;
end;
$body$;

revoke all on function mgr.create_tenant_databases_script(text, int, int) from public;
