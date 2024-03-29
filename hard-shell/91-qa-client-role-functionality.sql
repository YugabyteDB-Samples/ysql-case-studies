\t on

call mgr.set_role('qa');
delete from support.incidents;
delete from data.masters;

\c d3 d3$client
----------------------------------------------------------------------------------------------------

select client_safe.rule_off('positive tests for the exposed api.', 'level_2');

call insert_master_and_details(   '{"m": "Fred", "ds": []}', '');
call insert_master_and_details(   '{"m": "Joan", "ds": ["saw"]}', '');
call insert_master_and_details(   '{"m": "Joan", "ds": ["screwdriver"]}', '');
call insert_master_and_details(   '{"m": "John", "ds": ["kettle", "pitcher", "saucepan"]}', '');
call insert_master_and_details(   '{"m": "Mary", "ds": ["shampoo", "soap", "toothbrush", "towel"]}', '');

call do_master_and_details_report('{"m": "Fred"}', '');
call do_master_and_details_report('{"m": "Joan"}', '');
call do_master_and_details_report('{"m": "John"}', '');
call do_master_and_details_report('{"m": "Mary"}', '');

----------------------------------------------------------------------------------------------------
select client_safe.rule_off('"user error" tests for the exposed api.', 'level_2');

select client_safe.rule_off(  '{"m": "Jo", "ds": []}', 'level_3');
call insert_master_and_details('{"m": "Jo", "ds": []}', '');

select client_safe.rule_off(   '{"m": "Joan", "ds": ["hammer", "file", "saw"]}', 'level_3');
call insert_master_and_details('{"m": "Joan", "ds": ["hammer", "file", "saw"]}', '');

select client_safe.rule_off(   '{"m": "Arthur", "ds": ["kitchen scissors", "saucer", "spatula", "spatula", "kitchen scissors"]}', 'level_3');
call insert_master_and_details('{"m": "Arthur", "ds": ["kitchen scissors", "saucer", "spatula", "spatula", "kitchen scissors"]}', '');

select client_safe.rule_off(      '{"m": "Bill"}', 'level_3');
call do_master_and_details_report('{"m": "Bill"}', '');

----------------------------------------------------------------------------------------------------
select client_safe.rule_off('"unexpected error" tests for the exposed api.', 'level_2');

select client_safe.rule_off(   '{"m": "Chris", "ds": ["drill", "small portable workbench"]}', 'level_3');
call insert_master_and_details('{"m": "Chris", "ds": ["drill", "small portable workbench"]}', '');

----------------------------------------------------------------------------------------------------
\c d3 d3$mgr
call mgr.set_role('support');

select client_safe.rule_off('INCIDENTS', 'level_2');
select line from support.incidents_report();

\t off
\c d3 d3$client
