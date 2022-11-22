set role d2$json;

-- Add an application-specific outcome code.
alter type json_utils.outcome_codes add value if not exists 'm-and-ds report success';


create schema json_helpers authorization d2$json;
grant usage on schema json_helpers to d2$qa;

-- INPUT PARAMETERIZATION ------------------------------------------------------

-- For json_utils.json_object_keys_ok()
create type  json_helpers.master_m as (m text);

-- For json_shim.insert_master_and_details()
create procedure json_helpers.m_and_ds(
  j          in    text,
  result     inout code.m_and_ds,
  j_outcome  inout text)

  security invoker
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  success constant json_utils.outcome_codes not null := 'bare success';

  /*
    We allow both of these (when parameterizing "insert"):

     {"m": "Fred", "ds": []}
     {"m": "Fred", "ds": null}

    To mean "Fred has no details". This implies that the "ds" key has two allowed
    JSON datatypes: "array" and "null". This is reflected in the value for "key_facts".

    However, this

     {"m": "Fred", "ds": [null]}

    is disallowed. This is reflected in the use of "json_utils.array_elements_all_same_type(r)".
    It is called only to test that each of the elements of the "ds" array (when it isn't empty)
    is JSON "string".
  */
  key_facts constant json_utils.key_facts[] not null :=
    array[('m', 'string', true), ('ds', 'array', false), ('ds', 'null', false)];
begin
  j_outcome := json_utils.json_object_keys_ok(j, key_facts);
  if (j_outcome::jsonb ->> 'outcome_code')::json_utils.outcome_codes = success then
    declare
      jb       jsonb not null := j;
    begin
      j_outcome := json_utils.array_elements_all_same_type(jb, 'ds', 'string');
      if (j_outcome::jsonb ->> 'outcome_code')::json_utils.outcome_codes = success then
        result := jsonb_populate_record(null::code.m_and_ds, jb);
      end if;
    end;
  end if;
end;
$body$;

-- For json_shim.do_master_and_details_report()
create procedure json_helpers.mv(
  j           in    text,
  result      inout text,
  j_outcome   inout text)

  security invoker
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  success constant json_utils.outcome_codes not null := 'bare success';
  key_facts constant json_utils.key_facts[] not null := array[('m', 'string', true)];
begin
  j_outcome := json_utils.json_object_keys_ok(j, key_facts);

  if (j_outcome::jsonb ->> 'outcome_code')::json_utils.outcome_codes = success then
    result := (jsonb_populate_record(null::json_helpers.master_m, j::jsonb)).m;
  end if;
end;
$body$;

-- OUTPUT PARAMETERIZATION -----------------------------------------------------

-- For json_helpers.do_master_and_details_report()
create type json_helpers.m_and_ds_report as (outcome_code json_utils.outcome_codes, m_and_ds code.m_and_ds);

create function json_helpers.master_and_details_report(
  m_and_ds in code.m_and_ds)
  returns text

  immutable
  security invoker
  set search_path = pg_catalog, pg_temp
  language sql
as $body$
  select to_jsonb(
      (
        'm-and-ds report success',
        m_and_ds
      )::json_helpers.m_and_ds_report
    )::text;
$body$;

-- THE API ---------------------------------------------------------------------

create schema json_shim authorization d2$json;
grant usage on schema json_shim to d2$api;

create procedure json_shim.insert_master_and_details(
  j in text,
  j_outcome inout text)

  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  success     constant json_utils.outcome_codes not null := 'bare success';
  user_error  constant json_utils.outcome_codes not null := 'user error';

  m_and_ds      code.m_and_ds;
  outcome_code  json_utils.outcome_codes  not null := '';
  outcome_msg   text                      not null := '';
begin
  call json_helpers.m_and_ds(j, m_and_ds, j_outcome);
  if (j_outcome::jsonb ->> 'outcome_code')::json_utils.outcome_codes = success then
    call code.insert_master_and_details(m_and_ds, outcome_code, outcome_msg);
    case outcome_code
      when success then
        j_outcome := json_utils.bare_success();

      when user_error then
        j_outcome := json_utils.expected_error(outcome_code, outcome_msg);
    end case;
  end if;
end;
$body$;

revoke all     on procedure json_shim.insert_master_and_details(text, text) from public;
grant  execute on procedure json_shim.insert_master_and_details(text, text) to   d2$api;

--------------------------------------------------------------------------------

create procedure json_shim.do_master_and_details_report(
  j in text,
  j_outcome inout text)

  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  success     constant json_utils.outcome_codes not null := 'bare success';
  user_error  constant json_utils.outcome_codes not null := 'user error';

  tmp_mv        text                               := null;
  m_and_ds      code.m_and_ds                      := null;
  outcome_ok    boolean                   not null := false;
  outcome_code  json_utils.outcome_codes  not null := '';
  outcome_msg   text                      not null := '';
begin
  call json_helpers.mv(j, tmp_mv, j_outcome);
  if (j_outcome::jsonb ->> 'outcome_code')::json_utils.outcome_codes = success then
    declare
      -- Here only when (tmp_mv is not null).
      mv constant text not null := tmp_mv;
    begin
      call code.do_master_and_details_report(mv, m_and_ds, outcome_code, outcome_msg);
      case outcome_code
        when success then
          case
            when (m_and_ds is not null) then
              j_outcome := json_helpers.master_and_details_report(m_and_ds);

            else
              j_outcome := json_utils.expected_error(outcome_code, outcome_msg);
          end case;
        when user_error then
          j_outcome := json_utils.expected_error(outcome_code, outcome_msg);
      end case;
    end;
  end if;
end;
$body$;

revoke all     on procedure json_shim.do_master_and_details_report(text, text) from public;
grant  execute on procedure json_shim.do_master_and_details_report(text, text) to   d2$api;
