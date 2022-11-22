/*
  No 'drop owned by' because it has to be done in a database where
  obects might be owned. But this will be run in the "postgres" database.
  Anyway an improper role ought not to own anything.
  So imply handle any unlikely "2BP01" error and report on any
  surviving improper roles when done.
*/;
create procedure mgr.drop_all_improper_ybmt_roles()
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  r name not null := '';
  roles_to_be_dropped constant name[] := (
      select array_agg(name order by name) from mgr.improper_ybmt_roles
    );

  expected_msg_template constant text not null :=
    'role "%s" cannot be dropped because some objects depend on it';
  msg text not null := '';
begin
  if (roles_to_be_dropped is not null and cardinality(roles_to_be_dropped) > 0) then
    foreach r in array roles_to_be_dropped loop
      begin
        execute format('drop role %I', r);
      exception when dependent_objects_still_exist then
        get stacked diagnostics msg = message_text;
        assert msg = format(expected_msg_template, r), 'Unexpected: '||msg;
      end;
    end loop;
  end if;
end;
$body$;

revoke execute on procedure mgr.drop_all_improper_ybmt_roles() from public;
