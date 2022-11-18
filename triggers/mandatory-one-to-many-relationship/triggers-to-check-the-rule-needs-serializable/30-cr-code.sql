call mgr.set_role('code');
call mgr.revoke_all_from_public('schema', 'code');
call mgr.grant_priv(   'usage', 'schema', 'code', 'client');

\ir 31-cr-insert-and-delete-subprograms.sql
\ir 32-cr-reporting-subprograms.sql
\ir 33-cr-qa-subprograms.sql
\ir 34-cr-text-equals.sql
