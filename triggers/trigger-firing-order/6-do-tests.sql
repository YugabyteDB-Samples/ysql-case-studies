\t on
call log_a_comment(      $$upsert ('Mary', array['shampoo'])$$);
call upsert_master_insert_details(('Mary', array['shampoo'])::m_and_ds);

call log_a_comment(      $$upsert ('Bill', array['cup', 'saucer'])$$);
call upsert_master_insert_details(('Bill', array['cup', 'saucer'])::m_and_ds);

select master_and_details_report();

call log_a_comment($$delete detail 'shampoo'$$);
call delete_specified_details('shampoo');
select master_and_details_report();

call log_a_comment($$cascade-delete master 'Bill'$$);
call cascade_delete_specified_masters('Bill');
select master_and_details_report();

call log_a_comment(      $$upsert ('Mary', array['soap', 'sponge', 'flannel'])$$);
call upsert_master_insert_details(('Mary', array['soap', 'sponge', 'flannel'])::m_and_ds);
select master_and_details_report();

call log_a_comment( $$update 'soap' to 'towel')$$);
call update_one_detail('soap', 'towel');
select master_and_details_report();

select trigger_firings();
\t off
