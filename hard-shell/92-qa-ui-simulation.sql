\t on
\c d2 d2$mgr
set role d2$qa;

delete from support.incidents;
delete from data.masters;
----------------------------------------------------------------------------------------------------
select mgr.rule_off('positive tests for qa''s client-side simulation');

select mgr.rule_off( $$insert('Fred', null)$$, 'rule');
select qa_ui_simulation.ui_simulation_insert('Fred', null);

select mgr.rule_off( $$insert('Dick', array[]::text[])$$, 'rule');
select qa_ui_simulation.ui_simulation_insert('Dick', array[]::text[]);

select mgr.rule_off( $$insert('Joan', array['saw'])$$, 'rule');
select qa_ui_simulation.ui_simulation_insert('Joan', array['saw']);

select mgr.rule_off( $$insert('Joan', array['screwdriver'])$$, 'rule');
select qa_ui_simulation.ui_simulation_insert('Joan', array['screwdriver']);

select mgr.rule_off( $$insert('John', array['kettle', 'pitcher', 'saucepan'])$$, 'rule');
select qa_ui_simulation.ui_simulation_insert('John', array['kettle', 'pitcher', 'saucepan']);

select mgr.rule_off( $$insert('Mary', array['shampoo', 'soap', 'toothbrush', 'towel'])$$, 'rule');
select qa_ui_simulation.ui_simulation_insert('Mary', array['shampoo', 'soap', 'toothbrush', 'towel']);

select mgr.rule_off($$report ('Fred')$$, 'rule');
select qa_ui_simulation.ui_simulation_report('Fred');

select mgr.rule_off($$report ('Dick')$$, 'rule');
select qa_ui_simulation.ui_simulation_report('Dick');

select mgr.rule_off($$report ('Joan')$$, 'rule');
select qa_ui_simulation.ui_simulation_report('Joan');

select mgr.rule_off($$report ('John')$$, 'rule');
select qa_ui_simulation.ui_simulation_report('John');

select mgr.rule_off($$report ('Mary')$$, 'rule');
select qa_ui_simulation.ui_simulation_report('Mary');

----------------------------------------------------------------------------------------------------
select mgr.rule_off('"user error" tests for qa''s client-side simulation');

select mgr.rule_off( $$insert('Jo', array[]::text[])$$, 'rule');
select qa_ui_simulation.ui_simulation_insert('Jo', array[]::text[]);

select mgr.rule_off( $$insert('Joan', array['hammer', 'file', 'saw'])$$, 'rule');
select qa_ui_simulation.ui_simulation_insert('Joan', array['hammer', 'file', 'saw']);

select mgr.rule_off( $$insert('Arthur', array['kitchen scissors', 'saucer', 'spatula', 'spatula', 'kitchen scissors'])$$, 'rule');
select qa_ui_simulation.ui_simulation_insert('Arthur', array['kitchen scissors', 'saucer', 'spatula', 'spatula', 'kitchen scissors']);

select mgr.rule_off($$report ('Bill'))$$, 'rule');
select qa_ui_simulation.ui_simulation_report('Bill');

----------------------------------------------------------------------------------------------------
select mgr.rule_off('"client code error" tests for qa''s client-side simulation');
select mgr.rule_off( $$insert('Bert', array[null]::text[])$$, 'rule');
select qa_ui_simulation.ui_simulation_insert('Bert', array[null]::text[]);

----------------------------------------------------------------------------------------------------
select mgr.rule_off('"unexpected error" tests for qa''s client-side simulation');

select mgr.rule_off( $$insert('Joan', array['drill', 'small portable workbench'])$$, 'rule');
select qa_ui_simulation.ui_simulation_insert('Joan', array['drill', 'small portable workbench']);

\t off
