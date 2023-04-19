\set VERBOSITY default
:c
------------------------------------------------------------------------------------------
-- Re-configure the cluster for YBMT 

\ir ../01-re-initialize-ybmt-clstr.sql
\c yugabyte yugabyte
\t on

\o re-config-clstr.txt
select client_safe.rule_off('Immediately after re-configuring for YBMT');
select mgr.dbs_with_comments();
select mgr.roles_with_comments();
\o

------------------------------------------------------------------------------------------
-- Create the tenant database and its local roles.

\set lower_db_no 9
\set upper_db_no 9
\set db d9
\set db_name '\'':db'\''
\set mgr d9$mgr
\set cln d9$client
\ir ../02-drop-and-re-create-tenant-databases.sql

\o cr-tenant-db-and-install-app.txt
\c :db :mgr
\t on
call mgr.comment_on_current_db('Tenant database for SV2023-conference demo');

call mgr.cr_role(
  nickname    => 'data',
  with_schema => true,
  comment     => 'Owns the tables and supporting objects');

call mgr.cr_role(
  nickname    => 'code',
  with_schema => true,
  comment     => 'Owns the code that encapsulates the intended access to the data.');

------------------------------------------------------------------------------------------
-- Install the "data" objects.

call mgr.set_role('data');
call mgr.grant_priv(
  priv             => 'usage',
  object_kind      => 'schema',
  object           => 'data',
  grantee_nickname => 'code');

create table data.t(k serial, v text not null);

call mgr.revoke_all_from_public('table', 'data.t');
call mgr.grant_priv(
  priv             => 'select, insert',
  object_kind      => 'table',
  object           => 'data.t',
  grantee_nickname => 'code');

call mgr.revoke_all_from_public('sequence', 'data.t_k_seq');
call mgr.grant_priv(
  priv             => 'usage',
  object_kind      => 'sequence',
  object           => 'data.t_k_seq',
  grantee_nickname => 'code');

create function data.coerce_v_lower_case()
  returns trigger
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
begin
  new.v := lower(new.v);
  return new;
end;
$body$;

call mgr.revoke_all_from_public('function', 'data.coerce_v_lower_case()');

create trigger coerce_v_lower_case
  before insert or update
  on data.t
  for each row
  execute function data.coerce_v_lower_case();

------------------------------------------------------------------------------------------
-- Install the "code" objects.

call mgr.set_role('code');
call mgr.grant_priv(
  priv             => 'usage',
  object_kind      => 'schema',
  object           => 'code',
  grantee_nickname => 'client');

create procedure code.insert_t(vs in text[])
  set search_path = pg_catalog, pg_temp
  security definer
  language plpgsql
as $body$
begin
  insert into data.t(v) select unnest(vs);
end;
$body$;

call mgr.revoke_all_from_public('procedure', 'code.insert_t');
call mgr.grant_priv(
  priv             => 'execute',
  object_kind      => 'procedure',
  object           => 'code.insert_t',
  grantee_nickname => 'client');

create function code.t_rows()
  returns table(kk int, vv text)
  set search_path = pg_catalog, pg_temp
  security definer
  stable
  language plpgsql
as $body$
begin
  for kk, vv in select t.k, t.v from data.t order by k loop
    return next;
  end loop;
end;
$body$;

call mgr.revoke_all_from_public('function', 'code.t_rows');
call mgr.grant_priv(
  priv             => 'execute',
  object_kind      => 'function',
  object           => 'code.t_rows',
  grantee_nickname => 'client');

create function code.lockdown_example()
  returns text
  set search_path = pg_catalog, pg_temp
  security invoker
  stable
  language plpgsql
as $body$
begin
  perform 10/2;
  assert false, 'Unexpected.';
exception when insufficient_privilege then
  return '"insufficient_privilege" handled for "10/2".';
end;
$body$;

call mgr.revoke_all_from_public('function', 'code.lockdown_example');
call mgr.grant_priv(
  priv             => 'execute',
  object_kind      => 'function',
  object           => 'code.lockdown_example',
  grantee_nickname => 'client');

------------------------------------------------------------------------------------------
-- Take the tenant database's inventory.

select client_safe.rule_off('After re-configuring and installing "'||:db_name||'".');
select mgr.dbs_with_comments();
select mgr.roles_with_comments();
select mgr.schema_objects(local=>true);
select mgr.triggers();

------------------------------------------------------------------------------------------

\c :db :cln
set search_path = pg_catalog, code, client_safe, pg_temp;

select rule_off('Testing the app.');
call insert_t(array['dog', 'CAT', 'Frog']);
select kk, vv from t_rows();

select lockdown_example();
------------------------------------------------------------------------------------------
\t off

\o
