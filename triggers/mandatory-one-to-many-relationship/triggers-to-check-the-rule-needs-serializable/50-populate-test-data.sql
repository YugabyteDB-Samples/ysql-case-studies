\c d5 d5$client

-- Get a clean start
\t on
call cascade_delete_specified_masters();
select master_and_details_report();

call insert_master_and_details(
  ('Bruce', array['needle', 'thread', 'thimble', 'scissors'])::m_and_ds);

call insert_master_and_details(
  ('Mary', array['shampoo', 'soap', 'toothbrush', 'towel'])::m_and_ds);

call insert_master_and_details(
  ('Joan', array['saw', 'screwdriver', 'chisel', 'drill'])::m_and_ds);

call insert_master_and_details(
  ('Bill', array['cup', 'saucer', 'plate', 'bowl', 'tankard'])::m_and_ds);

call insert_master_and_details(
  ('Arthur', array['protractor', 'ruler', 'compass', 'dividers'])::m_and_ds);

select master_and_details_report();
