\c postgres clstr$mgr
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

\o :script_filename
select mgr.create_tenant_databases_script(:quoted_script_filename, :lower_db_no, :upper_db_no);
\o
\i :script_filename

select '';

with c1(d) as (
  select regexp_replace(datname, '^d', '')::int
from pg_database
where not (datistemplate or datname in ('postgres', 'system_platform')))
select 'd'||d::text as datname from c1 order by d;

\t off
