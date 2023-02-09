call mgr.set_role('qa');

delete from support.incidents;
delete from data.masters;
\t on
select client_safe.rule_off('UNIT TESTS FOR "code" subprograms. (These aren''t exposed via the "client" role.)', 'level_2');

\pset null '<NULL>'
\set empty '\'\'::json_utils.outcome_codes'

call qa_code.insert_master_and_details(('Barry', array['spanner', 'pliers', 'file']));
call qa_code.insert_master_and_details(('Barry', array['screwdiver', 'drill']));

call code.insert_master_and_details(('Alice', array['fork', 'spoon', 'knife']),         :empty, '');
call code.insert_master_and_details(('Joan',  array['fork', 'spoon', 'knife', 'fork']), :empty, '');
call code.insert_master_and_details(('Alice', array['fork', 'teaspoon', 'teaspoon']),   :empty, '');

select qa_code.master_and_details_report_all_rows();
select qa_code.master_and_details_report_one_row ('Barry'::text);

call code.do_master_and_details_report('Barry', null, :empty, '');
call code.do_master_and_details_report('Alice', null, :empty, '');
call code.do_master_and_details_report('Joan',  null, :empty, '');

call code.do_master_and_details_report('Mike',  null, :empty, '');
\pset null ''

\t off
