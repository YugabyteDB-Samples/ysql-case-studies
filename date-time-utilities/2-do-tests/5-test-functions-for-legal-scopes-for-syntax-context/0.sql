-- Force the use of qualified idenitifiers
set search_path = pg_catalog, pg_temp;

\t on
select client_safe.rule_off('Helper functions for rules 2, 3, and 4 for specifying the UTC offset', 'level_2');

select client_safe.rule_off('The "occurrences()" function', 'level_3');
select ext_tz_names.occurrences('WEST');
select ext_tz_names.occurrences('America/New_York');
select ext_tz_names.occurrences('XJT');
select ext_tz_names.occurrences('MST');

select client_safe.rule_off('The "legal_scopes_for_syntax_context()" function', 'level_3');
select x from ext_tz_names.legal_scopes_for_syntax_context('WEST');
select x from ext_tz_names.legal_scopes_for_syntax_context('America/New_York');
select x from ext_tz_names.legal_scopes_for_syntax_context('XJT');
select x from ext_tz_names.legal_scopes_for_syntax_context('MST');
\t off
