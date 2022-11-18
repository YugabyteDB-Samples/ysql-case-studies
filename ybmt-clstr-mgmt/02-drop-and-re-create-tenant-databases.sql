\c yugabyte clstr$mgr
\t on
\x off
select mgr.random_script_filename() as filename
\gset script_
\set quoted_script_filename '\'':script_filename'\''

\o :script_filename
select mgr.drop_tenant_databases_script(:quoted_script_filename, :lower_db_no, :upper_db_no);
\o
\i :script_filename

call mgr.drop_all_improper_ybmt_roles();
select z from mgr.improper_ybmt_roles();

select mgr.random_script_filename() as filename
\gset script_
\set quoted_script_filename '\'':script_filename'\''

\o :script_filename
select mgr.create_tenant_databases_script(:quoted_script_filename, :lower_db_no, :upper_db_no);
\o
\i :script_filename
\t off

call mgr.assert_no_db_has_privs_granted_to_public();
