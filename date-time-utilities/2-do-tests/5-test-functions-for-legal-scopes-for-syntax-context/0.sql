\t on

select rule_off('Helper functions for rules 2, 3, and 4 for specifying the UTC offset', 'level_2');

select rule_off('The "occurrences()" function', 'level_3');
select occurrences('WEST');
select occurrences('America/New_York');
select occurrences('XJT');
select occurrences('MST');

select rule_off('The "legal_scopes_for_syntax_context()" function', 'level_3');
select x from legal_scopes_for_syntax_context('WEST');
select x from legal_scopes_for_syntax_context('America/New_York');
select x from legal_scopes_for_syntax_context('XJT');
select x from legal_scopes_for_syntax_context('MST');
\t off
