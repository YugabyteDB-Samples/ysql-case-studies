call mgr.cr_role('support',                      comment=>'Owns the Incident Logging subsystem.');
call mgr.cr_role('qa',      with_schema=> false, comment=>'Owns the QA subsystem.');
call mgr.cr_role('data',                         comment=>'Owns the tables and associated objects.');
call mgr.cr_role('code',                         comment=>'Owns the code that manipulates the contents of the tables owned by "data".');
call mgr.cr_role('json',    with_schema=> false, comment=>'Owns the "JSON Shim" for the subprograms owned by "code".');
call mgr.cr_role('api',                          comment=>'Owns the wrappers tha jointly define the API for "client".');

call mgr.set_role_search_path('client', 'api, client_safe, pg_catalog, pg_temp');
