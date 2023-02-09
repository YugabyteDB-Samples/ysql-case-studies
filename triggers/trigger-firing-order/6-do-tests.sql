\t on
call trg_firing_order.log_a_comment(      $$upsert ('Mary', array['shampoo'])$$);
call trg_firing_order.upsert_master_insert_details(('Mary', array['shampoo'])::trg_firing_order.m_and_ds);

call trg_firing_order.log_a_comment(      $$upsert ('Bill', array['cup', 'saucer'])$$);
call trg_firing_order.upsert_master_insert_details(('Bill', array['cup', 'saucer'])::trg_firing_order.m_and_ds);

select trg_firing_order.master_and_details_report();

call trg_firing_order.log_a_comment($$delete detail 'shampoo'$$);
call trg_firing_order.delete_specified_details('shampoo');
select trg_firing_order.master_and_details_report();

call trg_firing_order.log_a_comment($$cascade-delete master 'Bill'$$);
call trg_firing_order.cascade_delete_specified_masters('Bill');
select trg_firing_order.master_and_details_report();

call trg_firing_order.log_a_comment(      $$upsert ('Mary', array['soap', 'sponge', 'flannel'])$$);
call trg_firing_order.upsert_master_insert_details(('Mary', array['soap', 'sponge', 'flannel'])::trg_firing_order.m_and_ds);
select trg_firing_order.master_and_details_report();

call trg_firing_order.log_a_comment( $$update 'soap' to 'towel')$$);
call trg_firing_order.update_one_detail('soap', 'towel');
select trg_firing_order.master_and_details_report();

select trg_firing_order.trigger_firings();
\t off
