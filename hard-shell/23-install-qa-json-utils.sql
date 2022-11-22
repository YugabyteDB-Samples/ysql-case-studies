set role d2$qa;

create schema qa_json_utils authorization d2$qa;
--------------------------------------------------------------------------------

create function qa_json_utils.json_object_keys_ok_outcome(
  caption        in text,
  j              in text,
  key_facts_txt  in text)
  returns        table(z text)

  immutable
  security invoker
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  key_facts json_utils.key_facts[];
begin
  execute format('select array[%s]::json_utils.key_facts[]', key_facts_txt) into key_facts;

  declare
    j_outcome text not null := json_utils.json_object_keys_ok(j, key_facts);
  begin
    z := rpad('--- '||caption||' -', 120, '-');           return next;
    z := j;                                               return next;
    z := key_facts_txt;                                   return next;
    z := j_outcome;                                       return next;
  end;
end;
$body$;

revoke all on function qa_json_utils.json_object_keys_ok_outcome(text, text, text) from public;
