\c d5 d5$client
/*
  See "41-cr-insert-and-delete-subprograms.sql".
  You can't include "set transaction_isolation = serializable"
  among a procedure's attributes. Nor can you execute it dynamically.
  Moreover, while "set default_transaction_isolation" can be set as
  a procedure attribute, it has no effect on what the executingprocedure sees.

  The only viable approach is shown here. Notice that the triger function
  "enforce_mdry_1_to_m_rule_for_details()" checks that the isolation level
  is indeed the required "serializable".
*/
set default_transaction_isolation = serializable;
--------------------------------------------------------------------------------

-- Positive test.
call delete_specified_details('cup', 'saucer', 'plate', 'bowl');
select master_and_details_report();

-- Negative test.
do $body$
declare
  msg text not null := '';
begin
  call bad_insert_a_master_with_no_details();
  assert false, 'Unexpected';
exception
  when raise_exception then
    get stacked diagnostics msg = message_text;
    assert code.text_equals(msg, 'Inserting new master: each master must have at least one detail.'), 
      'Unexpected error msg: '||msg;
end;
$body$;

-- Positive tests setting up for negative test.
call code.cascade_delete_specified_masters('Algenon');
call code.insert_master_and_details(
  ('Algenon', array['forceps', 'swab', 'scalpel'])::code.m_and_ds
  );
call code.delete_specified_details('forceps');
call code.delete_specified_details('scalpel');
select master_and_details_report();

-- Negative test. Attempt to delete a master's last-remaining detail.
do $body$
declare
  msg text not null := '';
begin
  call code.delete_specified_details('swab');
  assert false, 'Unexpected';
exception
  when raise_exception then
    get stacked diagnostics msg = message_text;
    assert code.text_equals(msg, 'Deleting a detail: each master must have at least one detail.'), 
      'Unexpected error msg: '||msg;
end;
$body$;
select master_and_details_report();

-- Positive test.
call cascade_delete_specified_masters('Mary', 'Arthur');
select master_and_details_report();

-- Positive test.
call cascade_delete_specified_masters('Bill');
select master_and_details_report();

-- Positive test.
call cascade_delete_specified_masters();
select master_and_details_report();

-- Positive test.
-- Check that this works even when "masters" is empty.
call cascade_delete_specified_masters();
select master_and_details_report();

--------------------------------------------------------------------------------
/*
  INVESTIGATE THE (THEORETICAL) WEAKNESS
  Result is that 'Mary' is left with no details.
*/;

\c d5 d5$mgr

-- Positive tests setting up for positive test.
call mgr.set_role('data');
call mgr.grant_priv('execute', 'procedure', 'data.set_cascade_delete_flag(boolean)', 'code');
call mgr.set_role('code');
set default_transaction_isolation to 'serializable';
call code.cascade_delete_specified_masters('Mary');
call code.insert_master_and_details(
  ('Mary', array['shampoo', 'soap', 'toothbrush', 'towel'])::code.m_and_ds);

-- Positive test. Causes the expected error.
do $body$
declare
  msg text not null := '';
begin
  call code.delete_all_details_for_a_master('Mary');
  assert false, 'Unexpected';
exception
  when raise_exception then
    get stacked diagnostics msg = message_text;
    assert msg = 'Deleting a detail: each master must have at least one detail.', 
      'Unexpected error msg: '||msg;
end;
$body$;

/*
  Negative test. This will bypass the action of the
  "enforce_mdry_1_to_m_rule_for_detls" trigger only when
  "data.set_cascade_delete_flag()" is "security definer".
  But this is the wrong choice - as an ad hoc test will show.

  If you call "data.set_cascade_delete_flag()" when it's "security invoker",
  then, except when the invoking role is "data" (as it will be  when called
  from one of "data"'s triggers), it will fail with:

     permission denied to create temporary tables in database "play"

  because, by design, only "data" was granted the "temporary" permission
  on database "play".
*/;
do $body$
declare
  msg text not null := '';
begin
  call data.set_cascade_delete_flag(true);
  call code.delete_all_details_for_a_master('Mary');
  assert false, 'Unexpected';
exception
  when insufficient_privilege then
    get stacked diagnostics msg = message_text;
    assert msg like 'permission denied for schema pg_temp%', 
      'Unexpected error msg: '||msg;
end;
$body$;
select code.master_and_details_report();
--------------------------------------------------------------------------------

\c d5 d5$client
set default_transaction_isolation to 'serializable';
