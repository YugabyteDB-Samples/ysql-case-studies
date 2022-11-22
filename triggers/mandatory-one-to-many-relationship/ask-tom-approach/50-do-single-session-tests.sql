\t on
select decorated_master_and_details_report();

call delete_specified_details('', 'soap');
select decorated_master_and_details_report();

/*
  TEST THE "TWIZZLE".

  When "set constraints all immediate" is used,
  this fails with a server crash using YB.
  But without that, it fails with a spurious error:

  Key (dk)=(1) is still referenced from table "masters". Key (dk)=(1) is still referenced from table "masters".
*/;
call delete_specified_details('', 'shampoo');
select decorated_master_and_details_report();

call delete_specified_details('', 'cup', 'plate', 'saucer', 'tankard');
select decorated_master_and_details_report();

call cascade_delete_specified_masters('Joan', 'Bruce');
select decorated_master_and_details_report();

call delete_specified_details('', 'bowl');
select decorated_master_and_details_report();

\t off
