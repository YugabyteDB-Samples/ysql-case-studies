-- RED session
\c d5 d5$client

-- BLUE session
\c d5 d5$client

call cascade_delete_specified_masters();
call insert_master_and_details(
  ('Dick', array['shovel', 'rake'])::m_and_ds
  );
select master_and_details_report();

-- RED session
start transaction isolation level serializable;
call delete_specified_details('shovel');
select master_and_details_report(); -->> Dick >> rake

-- BLUE session
-- ERROR 25P02:
-- All transparent retries exhausted. Operation failed. Try again:
start transaction isolation level serializable;
call delete_specified_details('rake');
select master_and_details_report(); -->> Dick >> shovel

-- RED session
commit;  -->> Operation expired: Heartbeat... expired or aborted by a conflict: 40001

-- BLUE session
commit; -->> could not serialize access due to ...

select master_and_details_report();

/*

  CONCLUSION

  In this test, in YB, it's the RED session that gets the error on commit. And the BLUE commits OK.
  But in PG, it's the BLUE session that gets the error on commit. And the RED commits OK.

  This difference (in general, the choice of victim is unpredicatble) is to be expected.
  The essential point is simply that the mandatory 1:M rule remains honored.

*/;
