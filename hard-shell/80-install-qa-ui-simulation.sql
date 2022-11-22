set role d2$qa;

create schema qa_ui_simulation authorization d2$qa;
--------------------------------------------------------------------------------

create function qa_ui_simulation.pretty_api_outcome(j in text)
  returns table(z text)

  immutable
  security invoker
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  success                  constant json_utils.outcome_codes not null := 'bare success';
  user_error               constant json_utils.outcome_codes not null := 'user error';
  client_code_error        constant json_utils.outcome_codes not null := 'client code error';
  unexpected_error         constant json_utils.outcome_codes not null := 'unexpected error';
  m_and_ds_report_success  constant json_utils.outcome_codes not null := 'm-and-ds report success';
begin
  declare
    j_outcome  constant jsonb                     not null := j;
    outcome    constant json_utils.outcome_codes  not null := j_outcome ->> 'outcome_code';
  begin
    case
      when (outcome = success) then
        z := 'Success';                                                                 return next;

      when (outcome = m_and_ds_report_success) then
        declare
          result constant code.m_and_ds not null :=
            jsonb_populate_record(null::code.m_and_ds, j_outcome -> 'm_and_ds');

          ds text[] not null := result.ds;
          d  text            := null;
        begin
          z := result.m;                                                                return next;
          /*
            The emergent relation "data.masters left outer join data.details using (mk)"
            will have SQL NULL for the single resulting row when the current "masters"
            has no details.
          */
          foreach d in array ds loop
            case
              when d is not null then
                z := '  '||d;                                                           return next;
              else
                z := '  <no details>';                                                  return next;
            end case;
          end loop;
        end;

      when (outcome = user_error) or (outcome = client_code_error) then
        declare
          expected_error constant json_utils.expected_error not null :=
            jsonb_populate_record(null::json_utils.expected_error, j_outcome);
        begin
          z := outcome||': '||expected_error.reason;                                    return next;
        end;

      when (outcome = unexpected_error) then
        declare
          unexpected_error constant json_utils.unexpected_error not null :=
            jsonb_populate_record(null::json_utils.unexpected_error, j_outcome);
          tkt constant int not null := unexpected_error.ticket;
        begin
          z := outcome::text||':';                                                      return next;

          for z in (select line from support.incidents_report(array[tkt, tkt]))
          loop
                                                                                        return next;
          end loop;
        end;
    end case;
  end;

exception when invalid_text_representation then
  z := '"qa_ui_simulation.pretty_api_outcome()" failure: malformed input JSON document: '||j;         return next;
end;
$body$;

revoke execute on function qa_ui_simulation.pretty_api_outcome(text) from public;
grant  execute on function qa_ui_simulation.pretty_api_outcome(text) to   d2$client;

--------------------------------------------------------------------------------

create function qa_ui_simulation.ui_simulation_insert(m in text, ds in text[])
  returns table(z text)

  security invoker
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  rec        constant code.m_and_ds  not null := (m, ds);
  j          constant jsonb          not null := to_jsonb(rec);
  j_input    constant text           not null := j;
  j_outcome           text           not null := '';
  d                   text                    := '';
begin
  z := 'User input';                                                          return next;
  z := '----------';                                                          return next;
  z := rec.m;                                                                 return next;

  case
    when not ((ds is null) or (cardinality(ds) < 1) or (ds[1] is null)) then
      foreach d in array ds loop
        case
          when d is not null then
            z := '  '||d;                                                     return next;
          else
            z := '  <no details>';                                            return next;
        end case;
      end loop;
    else
      z := '  <no details>';                                                  return next;
  end case;
  z := '';                                                                    return next;

  z := 'j_input';                                                             return next;
  z := '-------';                                                             return next;
  z := j_input;                                                               return next;
  z := '';                                                                    return next;

  call api.insert_master_and_details(j_input, j_outcome);

  z := 'j_outcome';                                                           return next;
  z := '---------';                                                           return next;
  z := j_outcome;                                                             return next;
  z := '';                                                                    return next;

  z := 'Outcome display';                                                     return next;
  z := '---------------';                                                     return next;

  for z in (
    select a.z as z
    from qa_ui_simulation.pretty_api_outcome(j_outcome) as a)
  loop
                                                                              return next;
  end loop;
end;
$body$;

revoke execute on function qa_ui_simulation.ui_simulation_insert(text, text[]) from public;
grant  execute on function qa_ui_simulation.ui_simulation_insert(text, text[]) to   d2$client;

--------------------------------------------------------------------------------

create function qa_ui_simulation.ui_simulation_report(m text)
  returns table(z text)

  security invoker
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  k          constant json_helpers.master_m  not null := format('(%s)', m)::json_helpers.master_m;
  j          constant jsonb                  not null := to_jsonb(k);
  j_input    constant text                   not null := j;
  j_outcome           text                   not null := '';
begin
  z := 'User input';                                                          return next;
  z := '----------';                                                          return next;
  z := m;                                                                     return next;
  z := '';                                                                    return next;

  z := 'j_input';                                                             return next;
  z := '-------';                                                             return next;
  z := j_input;                                                               return next;
  z := '';                                                                    return next;

  call api.do_master_and_details_report(j_input, j_outcome);

  z := 'j_outcome';                                                           return next;
  z := '---------';                                                           return next;
  z := j_outcome;                                                             return next;
  z := '';                                                                    return next;

  z := 'Outcome display';                                                     return next;
  z := '---------------';                                                     return next;

  for z in (
    select a.z as z
    from qa_ui_simulation.pretty_api_outcome(j_outcome) as a)
  loop
                                                                              return next;
  end loop;
end;
$body$;

revoke execute on function qa_ui_simulation.ui_simulation_report(text) from public;
grant  execute on function qa_ui_simulation.ui_simulation_report(text) to   d2$client;
