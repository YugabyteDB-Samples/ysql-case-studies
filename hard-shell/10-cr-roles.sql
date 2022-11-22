\c d2 d2$mgr
call mgr.drop_all_regular_tenant_roles();
call mgr.comment_on_current_db('"Hard Shell" case study.');

/*
  procedure mgr.cr_role(
    nickname                   in text,
    with_create_on_db          in boolean = true,
    with_schema                in boolean = true,
    with_temp_on_db            in boolean = true,
    comment                    in text    = 'For ad hoc tests')
*/;

call mgr.cr_role('support',                      comment=>'Owns the Incident Logging subsystem.');
call mgr.cr_role('qa',      with_schema=> false, comment=>'Owns the QA subsystem.');
call mgr.cr_role('data',                         comment=>'Owns the tables and associated objects.');
call mgr.cr_role('code',                         comment=>'Owns the code that manipulates the contents of the tables owned by "data".');
call mgr.cr_role('json',    with_schema=> false, comment=>'Owns the "JSON Shim" for the subprograms owned by "code".');
call mgr.cr_role('api',                          comment=>'Owns the wrappers tha jointly define the API for "client".');

call mgr.set_role_path('client', 'api, mgr, pg_catalog, pg_temp');
