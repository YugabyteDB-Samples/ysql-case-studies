\c d5 d5$client
set default_transaction_isolation to 'serializable';
--------------------------------------------------------------------------------

call delete_specified_details('cup', 'saucer', 'plate', 'bowl');
select master_and_details_report();

/*
call delete_specified_details('tankard');
*/;

call insert_a_master_with_no_details('');
call delete_the_last_detail_for_a_master('');
select master_and_details_report();

call cascade_delete_specified_masters('Mary', 'Arthur');
select master_and_details_report();

call cascade_delete_specified_masters('Bill');
select master_and_details_report();

call cascade_delete_specified_masters();
select master_and_details_report();

-- Check that this works even when "masters" is empty.
call cascade_delete_specified_masters();
select master_and_details_report();

--------------------------------------------------------------------------------
/*
  INVESTIGATE THE (THEORETICAL) WEAKNESS
  Result is that 'Mary' is left with no details.
*/;

\c d5 d5$mgr
set role d5$data;
grant execute on procedure data.set_cascade_delete_flag(boolean) to d5$code;

set role d5$code;
set default_transaction_isolation to 'serializable';

call code.cascade_delete_specified_masters('Mary');
call code.insert_master_and_details(
  ('Mary', array['shampoo', 'soap', 'toothbrush', 'towel'])::code.m_and_ds
  );

/*
  Positive test. Causes the expected error:
    Deleting a detail: each master must have at least one detail
*/;
call code.call_delete_all_details_for_a_master('Mary', '');

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
call code.subvert_cascade_delete_flag('Mary', '');

select code.master_and_details_report();
--------------------------------------------------------------------------------

\c d5 d5$client
set default_transaction_isolation to 'serializable';
