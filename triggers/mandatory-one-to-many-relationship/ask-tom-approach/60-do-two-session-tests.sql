\c d4 d4$mgr
set role d4$u1;
call s.cascade_delete_specified_masters();

call s.insert_master_and_details(
  ('Mary', array['shampoo', 'soap', 'toothbrush', 'towel'])::s.m_and_ds);

/*

-- RED
\c d4 d4$mgr
set role d4$u1;
\t on
select s.decorated_master_and_details_report();
                                                  -- BLUE
                                                  \c d4 d4$mgr
                                                  set role d4$u1;
                                                  \t on
                                                  select s.decorated_master_and_details_report();
-- RED
begin;
call s.delete_specified_details('6', 'shampoo');
select s.decorated_master_and_details_report();
                                                  -- BLUE
                                                  begin;
                                                  call s.delete_specified_details('4', 'soap');
                                                  select s.decorated_master_and_details_report();
-- RED
commit;
select s.decorated_master_and_details_report();
                                                  -- BLUE
                                                  commit;
                                                  select s.decorated_master_and_details_report();
-- RED
begin;
call s.delete_specified_details('6', 'toothbrush');
select s.decorated_master_and_details_report();

                                                  -- BLUE
                                                  begin;
                                                  call s.delete_specified_details('4', 'towel');
-- RED
commit;
select s.decorated_master_and_details_report();
                                                  -- BLUE
                                                  User error: cannot delete a master's last surviving detail.        +
                                                              Key (dk)=(25) is still referenced from table "masters".
                                                  rollback;
                                                  select s.decorated_master_and_details_report();
*/;
