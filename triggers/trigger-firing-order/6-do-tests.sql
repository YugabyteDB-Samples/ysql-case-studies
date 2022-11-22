call u1.log_a_comment(      $$upsert ('Mary', array['shampoo'])$$);
call u1.upsert_master_insert_details(('Mary', array['shampoo'])::u1.m_and_ds);

call u1.log_a_comment(      $$upsert ('Bill', array['cup', 'saucer'])$$);
call u1.upsert_master_insert_details(('Bill', array['cup', 'saucer'])::u1.m_and_ds);

select u1.master_and_details_report();

call u1.log_a_comment($$delete detail 'shampoo'$$);
call u1.delete_specified_details('shampoo');
select u1.master_and_details_report();

call u1.log_a_comment($$cascade-delete master 'Bill'$$);
call u1.cascade_delete_specified_masters('Bill');
select u1.master_and_details_report();

call u1.log_a_comment(      $$upsert ('Mary', array['soap', 'sponge', 'flannel'])$$);
call u1.upsert_master_insert_details(('Mary', array['soap', 'sponge', 'flannel'])::u1.m_and_ds);
select u1.master_and_details_report();

call u1.log_a_comment( $$update 'soap' to 'towel')$$);
call u1.update_one_detail('soap', 'towel');
select u1.master_and_details_report();

\t on
select u1.trigger_firings();
\t off
