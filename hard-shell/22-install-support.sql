call mgr.set_role('support');
call mgr.revoke_all_from_public('schema', 'support');
call mgr.grant_priv(   'usage', 'schema', 'support', 'api');
call mgr.grant_priv(   'usage', 'schema', 'support', 'qa');

--------------------------------------------------------------------------------

-- "no information" is represented by the empty string.
create table support.incidents(
  ticket                serial primary key,
  unit                  text not null,
  returned_sqlstate     text not null,
  column_name           text not null,
  constraint_name       text not null,
  pg_datatype_name      text not null,
  message_text          text not null,
  table_name            text not null,
  schema_name           text not null,
  pg_exception_detail   text not null,
  pg_exception_hint     text not null,
  pg_exception_context  text not null);

call mgr.revoke_all_from_public('table', 'support.incidents');
call mgr.grant_priv(  'delete', 'table', 'support.incidents', 'qa');

create type support.stacked_diagnostics as (
  returned_sqlstate     text,
  column_name           text,
  constraint_name       text,
  pg_datatype_name      text,
  message_text          text,
  table_name            text,
  schema_name           text,
  pg_exception_detail   text,
  pg_exception_hint     text,
  pg_exception_context  text);

call mgr.revoke_all_from_public('type', 'support.stacked_diagnostics');
call mgr.grant_priv(   'usage', 'type', 'support.stacked_diagnostics', 'code');
call mgr.grant_priv(   'usage', 'type', 'support.stacked_diagnostics', 'json');

create procedure support.insert_incident(
  the_unit             in     text,
  stacked_diagnostics  in     support.stacked_diagnostics,
  ticket_no            inout  int)

  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
begin
  insert into support.incidents(
    unit,
    returned_sqlstate,
    column_name,
    constraint_name,
    pg_datatype_name,
    message_text,
    table_name,
    schema_name,
    pg_exception_detail,
    pg_exception_hint,
    pg_exception_context)
  values(
    the_unit,
    stacked_diagnostics.returned_sqlstate,
    stacked_diagnostics.column_name,
    stacked_diagnostics.constraint_name,
    stacked_diagnostics.pg_datatype_name,
    stacked_diagnostics.message_text,
    stacked_diagnostics.table_name,
    stacked_diagnostics.schema_name,
    stacked_diagnostics.pg_exception_detail,
    stacked_diagnostics.pg_exception_hint,
    stacked_diagnostics.pg_exception_context)
  returning ticket into ticket_no;
end;
$body$;
call mgr.revoke_all_from_public('procedure', 'support.insert_incident(text, support.stacked_diagnostics, int)');
call mgr.grant_priv( 'execute', 'procedure', 'support.insert_incident(text, support.stacked_diagnostics, int)', 'api');
--------------------------------------------------------------------------------

create function support.incidents_report_worker(
  i_ticket in int)
  returns table(z text)

  stable
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  -- a Type is always partnered by an implicitly create type with the same name and shape.
  r             support.incidents;

  pad  constant int                not null := 22;
  tab  constant text               not null := rpad(' ', (pad + 2));
  cr constant text                 not null :=
'
';
begin
  select
    ticket,
    unit,
    returned_sqlstate,
    column_name,
    constraint_name,
    pg_datatype_name,
    message_text,
    table_name,
    schema_name,
    pg_exception_detail,
    pg_exception_hint,
    pg_exception_context
  into r
  from support.incidents
  where ticket = i_ticket;

  z := rpad('unit:',                 pad)||r.unit;                            return next;
  z := rpad('returned_sqlstate:',    pad)||r.returned_sqlstate;               return next;
  z := rpad('message_text:',         pad)||r.message_text;                    return next;

  if r.pg_exception_detail != '' then
    declare
      len  int  not null := length(r.pg_exception_detail);
      cut  int  not null := 60;
      d1   text not null := substr(r.pg_exception_detail, 1, cut);
      d2   text not null := substr(r.pg_exception_detail, (cut + 1));
      d    text not null := case d2
                              when '' then d1
                              else         d1||cr||tab||d2
                            end;
    begin
      z := rpad('pg_exception_detail:',  pad)||d;                             return next;
    end;
  end if;

  if r.pg_exception_hint != '' then
    z := rpad('pg_exception_hint:',    pad)||r.pg_exception_hint;             return next;
  end if;
  if r.column_name != '' then
    z := rpad('column_name:',          pad)||r.column_name;                   return next;
  end if;
  if r.constraint_name != '' then
    z := rpad('constraint_name:',      pad)||r.constraint_name;               return next;
  end if;
  if r.pg_datatype_name != '' then
    z := rpad('pg_datatype_name:',     pad)||r.pg_datatype_name;              return next;
  end if;
  if r.table_name != '' then
    z := rpad('table_name:',           pad)||r.table_name;                    return next;
  end if;
  if r.schema_name != '' then
    z := rpad('schema_name:',          pad)||r.schema_name;                   return next;
  end if;

  z := '';                                                                    return next;
  z := 'pg_exception_context';                                                return next;
  z := '--------------------';                                                return next;
  z := r.pg_exception_context;                                                return next;
end;
$body$;

create function support.incidents_report(
  tickets in int[] = null::int[])
  returns table(line text)

  stable
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  nof_tickets constant int not null := (select count(*) from support.incidents);

  mode constant boolean not null :=
    (tickets is null) or (cardinality(tickets) < 1);

  where_clause constant text :=
    case mode
      when true then  null
      else            'where ticket in (select unnest('''||tickets::text||'''::int[]))'
   end;

  tkt int not null := 0;
begin
  case
    when nof_tickets > 0 then
      for
        -- Notice the dynamic SQL to accommdate possible "where" clause.
        tkt in execute format('
          select ticket
          from support.incidents
          %s
          order by ticket',
          where_clause)
      loop
        line := '';                                                           return next;
        line := 'TICKET NO. '||tkt::text;                                     return next;
        line := '';                                                           return next;
        for line in (select z from support.incidents_report_worker(tkt)) loop
          /* line is now populated */                                         return next;
        end loop;
        line := '';                                                           return next;
        line := rpad('_', 15, '_');                                           return next;
      end loop;

    else
      line := '';                                                             return next;
      line := 'There are no incidents to report.';                            return next;
      line := rpad('_', 15, '_');                                             return next;
  end case;
end;
$body$;
call mgr.revoke_all_from_public('function', 'support.incidents_report(int[])');
call mgr.grant_priv( 'execute', 'function', 'support.incidents_report(int[])', 'qa');
