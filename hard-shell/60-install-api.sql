/*
  Look at the section "PL/pgSQL's execution model" in the YSQL documentation:
  docs.yugabyte.com/preview/api/ysql/user-defined-subprograms-and-anon-blocks/plpgsql-execution-model/

  Look for this:

    Errors in a specific expression or SQL statement cannot be detected until runtime, and then
    not until (or unless) it is reached. Such an encounter depends on a current execution's control
    flow. And this is determined by run-time values like the actual arguments with which a subprogram
    is invoked or the results of executing SQL statements. Some particular programmer error might
    therefore remain undetected for a long time, even after a subprogram is deployed into the
    production system.

  Simply mis-spelling the name of a variable, at just one location in a subprogram's source code,
  can cause this kind of delayed error.

  The safest way to catch any such errors is to implement a last ditch "others" catch-all in each
  of the subprograms, here, that are the final expression of the "hard shell" API.
*/;

set role d3$api;

grant usage on schema api to d3$client;
grant usage on schema api to d3$qa;
--------------------------------------------------------------------------------

create procedure api.insert_master_and_details(j in text, j_outcome inout text)
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
begin
  call json_shim.insert_master_and_details(j, j_outcome);

exception
  when others then
    declare
      new_ticket            int not null := 0;
      unit                  constant text not null :=
                              'procedure api.insert_master_and_details(text, text)';
      stacked_diagnostics   support.stacked_diagnostics;
    begin
      get stacked diagnostics
        stacked_diagnostics.returned_sqlstate    = returned_sqlstate,
        stacked_diagnostics.column_name          = column_name,
        stacked_diagnostics.constraint_name      = constraint_name,
        stacked_diagnostics.pg_datatype_name     = pg_datatype_name,
        stacked_diagnostics.message_text         = message_text,
        stacked_diagnostics.table_name           = table_name,
        stacked_diagnostics.schema_name          = schema_name,
        stacked_diagnostics.pg_exception_detail  = pg_exception_detail,
        stacked_diagnostics.pg_exception_hint    = pg_exception_hint,
        stacked_diagnostics.pg_exception_context = pg_exception_context;

        call support.insert_incident(unit, stacked_diagnostics, new_ticket);
        j_outcome := json_utils.unexpected_error(new_ticket);
    end;
end;
$body$;

revoke all     on procedure api.insert_master_and_details(text, text) from public;
grant  execute on procedure api.insert_master_and_details(text, text) to   d3$client;
grant  execute on procedure api.insert_master_and_details(text, text) to   d3$qa;
--------------------------------------------------------------------------------

create procedure api.do_master_and_details_report(mv_in in text, j_outcome inout text)
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
begin
  call json_shim.do_master_and_details_report(mv_in, j_outcome);

exception
  when others then
    declare
      new_ticket            int not null := 0;
      unit                  constant text not null :=
                              'procedure api.insert_master_and_details(text, text)';
      stacked_diagnostics   support.stacked_diagnostics;
    begin
      get stacked diagnostics
        stacked_diagnostics.returned_sqlstate    = returned_sqlstate,
        stacked_diagnostics.column_name          = column_name,
        stacked_diagnostics.constraint_name      = constraint_name,
        stacked_diagnostics.pg_datatype_name     = pg_datatype_name,
        stacked_diagnostics.message_text         = message_text,
        stacked_diagnostics.table_name           = table_name,
        stacked_diagnostics.schema_name          = schema_name,
        stacked_diagnostics.pg_exception_detail  = pg_exception_detail,
        stacked_diagnostics.pg_exception_hint    = pg_exception_hint,
        stacked_diagnostics.pg_exception_context = pg_exception_context;

        call support.insert_incident(unit, stacked_diagnostics, new_ticket);
        j_outcome := json_utils.unexpected_error(new_ticket);
    end;
end;
$body$;

revoke all    on procedure api.do_master_and_details_report(text, text) from public;
grant execute on procedure api.do_master_and_details_report(text, text) to   d3$client;
grant execute on procedure api.do_master_and_details_report(text, text) to   d3$qa;
