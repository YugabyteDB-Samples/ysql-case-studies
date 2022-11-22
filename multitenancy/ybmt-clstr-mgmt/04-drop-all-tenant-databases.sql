\c postgres clstr$mgr
\t on
\x off
select mgr.random_script_filename() as filename
\gset script_
\set quoted_script_filename '\'':script_filename'\''

\o :script_filename
select mgr.drop_tenant_databases_script(:quoted_script_filename);
\o
\i :script_filename

call mgr.drop_all_improper_ybmt_roles();
select z from mgr.improper_ybmt_roles();

select '';

select datname
from pg_database
order by datistemplate, datname;
\t off
