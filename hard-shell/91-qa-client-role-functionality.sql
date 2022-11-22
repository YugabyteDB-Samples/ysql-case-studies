\t on

set role d2$qa;

delete from support.incidents;
delete from data.masters;

\c d2 d2$client

----------------------------------------------------------------------------------------------------

select rule_off('positive tests for the exposed api.');

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
select rule_off('"user error" tests for the exposed api.');

select rule_off(                '{"m": "Jo", "ds": []}', 'rule');
call insert_master_and_details( '{"m": "Jo", "ds": []}', '');

select rule_off(                '{"m": "Joan", "ds": ["hammer", "file", "saw"]}', 'rule');
call insert_master_and_details( '{"m": "Joan", "ds": ["hammer", "file", "saw"]}', '');

select rule_off(                '{"m": "Arthur", "ds": ["kitchen scissors", "saucer", "spatula", "spatula", "kitchen scissors"]}', 'rule');
call insert_master_and_details( '{"m": "Arthur", "ds": ["kitchen scissors", "saucer", "spatula", "spatula", "kitchen scissors"]}', '');

select rule_off(                   '{"m": "Bill"}', 'rule');
call do_master_and_details_report( '{"m": "Bill"}', '');

----------------------------------------------------------------------------------------------------
select rule_off('"unexpected error" tests for the exposed api.');

select rule_off(                '{"m": "Chris", "ds": ["drill", "small portable workbench"]}', 'rule');
call insert_master_and_details( '{"m": "Chris", "ds": ["drill", "small portable workbench"]}', '');

----------------------------------------------------------------------------------------------------
\c d2 d2$mgr
set role d2$support;

select mgr.rule_off('INCIDENTS');
select line from support.incidents_report();

\t off
\c d2 d2$client
