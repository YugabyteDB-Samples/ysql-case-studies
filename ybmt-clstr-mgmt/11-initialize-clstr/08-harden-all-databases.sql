set client_min_messages = 'warning';
drop type if exists mgr.tmp cascade;

create type mgr.tmp as (name text, istemplate boolean);
do $body$
declare
  d            mgr.tmp   not null := ('', false)::mgr.tmp;
  dbs constant mgr.tmp[] not null := (
    select array_agg((datname::text, datistemplate)::mgr.tmp) from pg_database);
begin
  foreach d in array dbs loop
    execute format('revoke all on database %I from public;', d.name);
    execute format('revoke all on database %I from postgres;', d.name);
    execute format('revoke all on database %I from yugabyte;', d.name);

    execute format($$alter database %I set transaction_isolation = 'read committed';$$,       d.name);
    execute format($$alter database %I set log_error_verbosity   = 'verbose';$$,              d.name);
    execute format($$alter database %I set client_min_messages   = 'warning';$$,              d.name);
    execute format($$alter database %I set search_path           =  pg_catalog, pg_temp;$$,   d.name);

    case d.name = 'yugabyte'
      when true then
        alter database yugabyte with allow_connections = true connection_limit = -1;
      else
        execute format('alter database %I with allow_connections = false connection_limit = 0', d.name);
    end case;

    case d.name ~ '^template'
      when true then
        assert d.istemplate,     d||' is not template';
      else
        assert not d.istemplate, d||' is template';
    end case;
  end loop;
end;
$body$;

drop type mgr.tmp cascade;
