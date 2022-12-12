set role d3$json;

create schema json_utils authorization d3$json;

grant usage on schema json_utils to d3$code;
grant usage on schema json_utils to d3$api;
grant usage on schema json_utils to d3$qa;
--------------------------------------------------------------------------------
/*
  The empty-string value is included in the enumeration so that it can be used as
  the actual argument for procedures with an "outcome_code inout" formal argument
  whose data type is json_utils.outcome_codes. For example:

    procedure code.insert_master_and_details()
    procedure code.do_master_and_details_report()
*/;
create type json_utils.outcome_codes as enum (
  '',
  'bare success',
  'user error',
  'client code error',
  'unexpected error');

grant usage on type json_utils.outcome_codes to d3$code;

-- OUTPUT PARAMETERIZATION

create type json_utils.bare_success      as (outcome_code json_utils.outcome_codes);
create type json_utils.expected_error    as (outcome_code json_utils.outcome_codes, reason text);
create type json_utils.unexpected_error  as (outcome_code json_utils.outcome_codes, ticket int);

create function json_utils.bare_success()
  returns text

  immutable
  security invoker
  set search_path = pg_catalog, pg_temp
  language sql
as $body$
  select (to_jsonb('(bare success)'::json_utils.bare_success))::text;
$body$;

revoke execute on function json_utils.bare_success() from public;
grant  execute on function json_utils.bare_success() to   d3$qa;

create function json_utils.expected_error(
  outcome_code in json_utils.outcome_codes,
  reason in text)
  returns text

  immutable
  security invoker
  set search_path = pg_catalog, pg_temp
  language sql
as $body$
  select (to_jsonb((outcome_code, reason)::json_utils.expected_error))::text;
$body$;

revoke execute on function json_utils.expected_error(json_utils.outcome_codes, text) from public;
grant  execute on function json_utils.expected_error(json_utils.outcome_codes, text) to   d3$qa;

create function json_utils.unexpected_error(
  ticket in int)
  returns text

  immutable
  security invoker
  set search_path = pg_catalog, pg_temp
  language sql
as $body$
  select (to_jsonb(
        ('unexpected error', ticket)::json_utils.unexpected_error
      )
    )::text;
$body$;

revoke execute on function json_utils.unexpected_error(int) from public;
grant  execute on function json_utils.unexpected_error(int) to   d3$api;

--------------------------------------------------------------------------------
-- Function json_object_keys_ok() 

create type json_utils.key_facts as (name text, data_type text, required boolean);
grant usage on type json_utils.key_facts to d3$qa;

create type json_utils.n_and_d as (name text, data_type text);

/*
  Checks the incoming text can be converted to a not null "jsonb" object,
  that it has only allowed key name-datatype pairs, and that all required keys are present.  
  If the checks pass, then the return is "bare_success". Else, the reurn is "expected_error"
  with a "reason" value that expresses on of the following:
    SQL NULL input for JSON document not allowed.
    Malformed input JSON document: %s
    Input document is not JSON object: %s
    Input JSON object is empty: %s
    Bad key-name-data-type pair: "%s"-"%s".
    The required key "%s" is not present.
*/
create function json_utils.json_object_keys_ok(
  j          in text,
  key_facts  in json_utils.key_facts[])
  returns       text

  immutable
  security invoker
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  client_code_error constant json_utils.outcome_codes not null := 'client code error';

  -- We'll need to split "key_facts" into two parallel arrays: "nds" and "reqd_statuses".
  nds             json_utils.n_and_d[]  not null := array[]::json_utils.n_and_d[];
  reqd_statuses   boolean[]             not null := array[]::boolean[];
  no_of_keys      int                   not null := cardinality(key_facts);

  -- Runners, etc.
  found_statuses  boolean[]             not null := array[]::boolean[];
  kn              text                  not null := '';
  kd              text                  not null := '';
  kfs             json_utils.key_facts  not null := ('', '', false);
  nd              json_utils.n_and_d    not null := ('', '');
  ok_so_far       boolean               not null := false;
  missing_key     text                  not null := '';

  -- The to-be-returned value.
  j_outcome       text                   not null := '';
begin
  declare
    -- Raises error if jb is null or not valid JSON.
    jb constant jsonb not null := j;
  begin
    -- Check jb is 'object'
    if jsonb_typeof(jb) != 'object' then
      return json_utils.expected_error(
        client_code_error,
        format('Input document is not JSON object: %s', j));
    end if;

    if (select count(*) from (select jsonb_object_keys(jb)) as a) < 1 then
      return json_utils.expected_error(
        client_code_error,
        format('Input JSON object is empty: %s', j));
    end if;

    /*
      Workaround for GitHub issue #13429.
      Assign to "nd" as an intermediary because the attempt to 
      assign directly to "key_facts[j].name" causes a compilation error.
    */
    for j in 1..no_of_keys loop
      found_statuses[j] := false;
      kfs              := key_facts[j];
      nd.name          := kfs.name;
      nd.data_type     := kfs.data_type;
      nds[j]           := nd;
      reqd_statuses[j] := kfs.required;
    end loop;

    for kn in (select jsonb_object_keys(jb)) loop
      kd := jsonb_typeof(jb->kn);
      nd := (kn, kd);
      if not (nd = any(nds)) then
        return json_utils.expected_error(
          client_code_error,
          format('Bad key-name-data-type pair: "%s"-"%s".', kn, kd));
      end if;
       
      -- Set "found_statuses[]" TRUE for the just-found key,
      declare
        idx int not null := 0;
      begin
        -- Find its "idx" value.
        for j in 1..no_of_keys loop
          idx := 0;
          if kn = nds[j].name then
            idx := j;
          end if;
          -- Mark that "idx" value as "found".
          if idx != 0 then
            found_statuses[idx] := true;
          end if;
        end loop;
      end;
    end loop;

    -- Check that all required keys were found. If more than one required key is missing,
    -- then we note just the first one and report an error. It would improve the usability
    -- to report them all. But doing this would increase the code complexity.
    -- The cost/benefit doesn't justify the effort (or the increased chance of bugs).
    for j in 1..no_of_keys loop
      if reqd_statuses[j] then
        if not found_statuses[j] then
          missing_key := nds[j].name;
          return json_utils.expected_error(
            client_code_error,
            format('The required key "%s" is not present.', missing_key));
        end if;
      end if;
    end loop;
  end;
  -- All tests succeded.
  return json_utils.bare_success();
exception
  when null_value_not_allowed then
    j_outcome := json_utils.expected_error(
                    client_code_error,
                    'SQL NULL input for JSON document not allowed.');
    return j_outcome;

  when invalid_text_representation then
    j_outcome := json_utils.expected_error(
                   client_code_error,
                   format('Malformed input JSON document: %s', j));
    return j_outcome;
end;
$body$;

revoke execute on function json_utils.json_object_keys_ok(text, json_utils.key_facts[]) from public;
grant  execute on function json_utils.json_object_keys_ok(text, json_utils.key_facts[]) to   d3$qa;

--------------------------------------------------------------------------------
-- Function array_elements_all_same_type() 

create function json_utils.array_elements_all_same_type(
  jb         in jsonb,
  arr_name   in text,
  json_type  in text)
  returns       text

  immutable
  security invoker
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  client_code_error constant json_utils.outcome_codes not null := 'client code error';
begin
  assert
    jsonb_typeof(jb) = 'object',
    'json_utils.array_elements_all_same_type(): input is not JSON object';

  declare
    arr      jsonb := jb -> arr_name;
    element  jsonb;
  begin
   if jsonb_typeof(arr) = 'null' then
      return json_utils.bare_success();

    elsif jsonb_typeof(arr) = 'array' and jsonb_array_length(arr) < 1 then
      return json_utils.bare_success();

    else
      for element in (select jsonb_array_elements(arr)) loop
        if jsonb_typeof(element) != json_type then
          return json_utils.expected_error(
            client_code_error,
            format('"%s" array has non-%s element: %s', arr_name, json_type, arr::text));
        end if;
      end loop;
    end if;
    return json_utils.bare_success();
  end;
end;
$body$;

revoke execute on function json_utils.array_elements_all_same_type(jsonb, text, text) from public;
grant  execute on function json_utils.array_elements_all_same_type(jsonb, text, text) to   d3$qa;
