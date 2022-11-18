-- Useful only for NEGATIVE testing.

create procedure code.bad_insert_a_master_with_no_details()
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  new_mk constant uuid not null := extensions.gen_random_uuid();
begin
  insert into data.masters(mk, v) values(new_mk, 'Jo');
end;
$body$;
call mgr.revoke_all_from_public('procedure', 'code.bad_insert_a_master_with_no_details()');
call mgr.grant_priv( 'execute', 'procedure', 'code.bad_insert_a_master_with_no_details()', 'client');

create procedure code.subvert_cascade_delete_flag(mv_in text, outcome inout text)
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  msg text not null := '';
begin
  call data.set_cascade_delete_flag(true);
  call code.delete_all_details_for_a_master(mv_in);
  outcome := 'Success.';
exception
  when insufficient_privilege then
    get stacked diagnostics msg = message_text;
    outcome :=  'Exception: '||msg;
end;
$body$;
call mgr.revoke_all_from_public('procedure', 'code.subvert_cascade_delete_flag(text, text)');
call mgr.grant_priv( 'execute', 'procedure', 'code.subvert_cascade_delete_flag(text, text)', 'client');
