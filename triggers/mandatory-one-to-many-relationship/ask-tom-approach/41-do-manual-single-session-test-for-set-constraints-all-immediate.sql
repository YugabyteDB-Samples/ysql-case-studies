\c d4 d4$client
call cascade_delete_specified_masters();
call insert_master_and_details(
  ('Bill', array['bowl', 'cup', 'plate', 'saucer', 'tankard'])::m_and_ds);

-- Shows that "bowl" is presently special:
select decorated_master_and_details_report();
call delete_specified_details('', 'bowl');

-- Now "cup" is special.
select decorated_master_and_details_report();
call delete_specified_details('', 'cup', 'plate');

-- Now "saucer" is special.
select decorated_master_and_details_report();
call delete_specified_details('', 'saucer');

-- Now "tankard" is special.
-- And it's the ONLY surviving "details" row for its "masters" row.
select decorated_master_and_details_report();

/*
  This causes a "FK violated" error that can be caiught in PL/pgSQL in
  PG but that cannot in YB -- where, rather, it escapes at "commit" time
  to the client.
/*;
call delete_specified_details('', 'tankard');
