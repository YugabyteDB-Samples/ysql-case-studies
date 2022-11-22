\c d4 d4$client

call cascade_delete_specified_masters();

call insert_master_and_details(
  ('Arthur', array['compass', 'dividers', 'protractor', 'ruler'])::m_and_ds);

call insert_master_and_details(
  ('Bill', array['bowl', 'cup', 'plate', 'saucer', 'tankard'])::m_and_ds);

call insert_master_and_details(
  ('Bruce', array['needle', 'scissors', 'thimble', 'thread'])::m_and_ds);

call insert_master_and_details(
  ('Joan', array['chisel', 'drill', 'saw', 'screwdriver'])::m_and_ds);

call insert_master_and_details(
  ('Mary', array['shampoo', 'soap', 'toothbrush', 'towel'])::m_and_ds);
