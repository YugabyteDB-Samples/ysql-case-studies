create procedure code.insert_a_master_with_no_details(outcome inout text)
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  msg             text not null := '';
  new_mk constant uuid not null := extensions.gen_random_uuid();
begin
  insert into data.masters(mk, v) values(new_mk, 'Jo');
  outcome := 'Success.';
exception
  when raise_exception then
    get stacked diagnostics msg = message_text;
    outcome :=  'Exception: '||msg;
end;
$body$;
revoke execute on procedure code.insert_a_master_with_no_details(text) from public;
grant  execute on procedure code.insert_a_master_with_no_details(text) to   d5$client;

create procedure code.delete_the_last_detail_for_a_master(outcome inout text)
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  msg text not null := '';
begin
  call code.cascade_delete_specified_masters('Algenon');
  call code.insert_master_and_details(
    ('Algenon', array['forceps', 'swab', 'scalpel'])::code.m_and_ds
    );
  call code.delete_specified_details('forceps');
  outcome := 'Deleted ''forceps'' OK.';
  call code.delete_specified_details('scalpel', 'swab');
  outcome := 'Success.';
exception
  when raise_exception then
    get stacked diagnostics msg = message_text;
    outcome := outcome||' Then on attempting to delete ''scalpel'', ''swab'': '||
      chr(10)||'Exception: '||msg;
end;
$body$;
revoke execute on procedure code.delete_the_last_detail_for_a_master(text) from public;
grant  execute on procedure code.delete_the_last_detail_for_a_master(text) to   d5$client;

create procedure code.call_delete_all_details_for_a_master(mv_in text, outcome inout text)
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  msg text not null := '';
begin
  call code.delete_all_details_for_a_master(mv_in);
  outcome := 'Success.';
exception
  when raise_exception then
    get stacked diagnostics msg = message_text;
    outcome :=  'Exception: '||msg;
end;
$body$;
revoke execute on procedure code.call_delete_all_details_for_a_master(text, text) from public;
grant  execute on procedure code.call_delete_all_details_for_a_master(text, text) to   d5$client;

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
revoke execute on procedure code.subvert_cascade_delete_flag(text, text) from public;
grant  execute on procedure code.subvert_cascade_delete_flag(text, text) to   d5$client;
