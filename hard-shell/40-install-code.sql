/*
  Notice that the code that this script creates has no "others" handlers by design.
  This is provided in the dynamically enclosing outermost procedure.
  "api.do_master_and_details_report()".
*/
set role d2$code;

--------------------------------------------------------------------------------
-- FOR THE code_helpers SCHEMA.

create schema code_helpers authorization d2$code;

-- For unit testing code and ad hoc demo code.
grant usage on schema code_helpers to d2$qa;

/*
  The "unique_violation" error reports only the first among possible several
  duplicates. Improve usability by reporting all dups, among both the
  to-be-inserted details and the existsing details (when the master isn't new).
*/;
create function code_helpers.details_dups(
  new_master in boolean,
  v_mk in uuid,
  new_details in text[])
  returns text

  stable
  security invoker
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  dups       text[]          := null;
  dups_list  text   not null := '';
begin
  case new_master
    when true then
      with
        new_ds(detail) as (select unnest(new_details)),

        grouped_ds(n, detail) as (
          select count(*), detail
          from new_ds
          group by detail)

      select array_agg(detail order by detail)
      into dups
      from grouped_ds
      where n > 1;

    when false then
      with
        new_ds(detail) as (select unnest(new_details)),

        existing_ds(detail) as (
          select detail from new_ds
          union all
          select v as detail
          from data.details
          where mk = v_mk),

        grouped_ds(n, detail) as (
          select count(*), detail
          from existing_ds
          group by detail)

      select array_agg(detail order by detail)
      into dups
      from grouped_ds
      where n > 1;
  end case;

  case
    when (dups is null) or (cardinality(dups) < 1) then
      dups_list := '';
    else
      declare
        d            text not null := '';
        quote        text not null := '''';
        comma_space  text not null := ', ';
      begin
        foreach d in array dups loop
          dups_list := dups_list||quote||d||quote||comma_space;
        end loop;
        dups_list := rtrim(dups_list, comma_space);
      end;
  end case;

  return dups_list;
end;
$body$;

revoke all on function code_helpers.details_dups(boolean, uuid, text[]) from public;

create type code_helpers.mk_and_ds as (mk uuid, ds text[]);
grant usage on type code_helpers.mk_and_ds to d2$qa;

--------------------------------------------------------------------------------
-- FOR THE code SCHEMA.

grant usage on schema code to d2$json;

create type code.m_and_ds as (m text,  ds text[]);
grant usage on type code.m_and_ds to d2$json;

-- For unit testing code and ad hoc demo code.
grant usage on schema code to d2$qa;
grant usage on type code.m_and_ds to d2$qa;

create procedure code.insert_master_and_details(
  m_and_ds      in    code.m_and_ds,
  outcome_code  inout json_utils.outcome_codes,
  outcome_msg   inout text)

  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  success      constant json_utils.outcome_codes  not null := 'bare success';
  user_error   constant json_utils.outcome_codes  not null := 'user error';
  bad_details           text                      not null := '';
begin
  outcome_msg := '';
  declare
    v_mk        uuid     not null := '9919f9cd-ae06-4c02-a9e6-256bc56b3b20';
    new_master  boolean  not null := true;
  begin
    -- Check "masters_v_chk" explicitly.
    if not ( length(m_and_ds.m) between 3 and 10) then
      outcome_code := user_error;
      outcome_msg  := 'The length of the master''s "v" attribute must be between 3 and 10';
      return;
    end if;

    begin
      insert into data.masters(v) values(m_and_ds.m) returning mk into v_mk;
    exception when unique_violation then
      select mk into v_mk from data.masters where v = m_and_ds.m;
      new_master := false;
    end;

    case
      when cardinality(m_and_ds.ds) < 1 then
        outcome_code := success;
      else        
        bad_details := code_helpers.details_dups(new_master, v_mk, m_and_ds.ds);
        case
          when bad_details = '' then

            /*
              It is hoped that the client-side code will enforce constraints like "masters_v_chk"
              and "details_v_chk". However, it might fail to do this properly.

              The "hard shell" code design can choose to (re-)check explicitly before attempting
              the "insert" so that a more helpful error message can be returned. This IS done for
              "masters_v_chk" (see above). But the corresponding check for "details_v_chk" is NOT
              done to demonstrate how the constraint violation error, should it occur, will bubble up
              to "api.insert_master_and_details()" and will be handled there as an "unexpected error".
            */
            begin
              with c(v) as (
                select (v_mk, m_and_ds.ds)::code_helpers.mk_and_ds)
              insert into data.details(mk, v)
              select (c.v).mk, arr.d
              from c cross join lateral unnest((c.v).ds) as arr(d);
              outcome_code := success;
            end;

          else
            declare
              reason text not null := 
                (case new_master when true  then 'New ' else 'Existing ' end)||
                ' master '''||m_and_ds.m||''' bad duplicate details: '||bad_details;
            begin
              outcome_code := user_error;
              outcome_msg  := reason;
            end;
        end case;
    end case;
  end;
end;
$body$;

revoke all     on procedure code.insert_master_and_details(code.m_and_ds, json_utils.outcome_codes, text) from public;
grant  execute on procedure code.insert_master_and_details(code.m_and_ds, json_utils.outcome_codes, text) to   d2$json;
grant  execute on procedure code.insert_master_and_details(code.m_and_ds, json_utils.outcome_codes, text) to   d2$qa;

--------------------------------------------------------------------------------
-- CREATE REPORT OF A SINGLE MASTER AND ITS DETAILS (IF ANY)

create procedure code.do_master_and_details_report(
  mv_in         in    text,
  result        inout code.m_and_ds,
  outcome_code  inout json_utils.outcome_codes,
  outcome_msg   inout text)

  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  success     constant text not null := 'bare success';
  user_error  constant text not null := 'user error';
begin
  outcome_msg := '';
  declare
    /*
      "mv_in" cannot be null because the JSON translation already checked for this.
      Doing this assignment in an inner block that handles "others" provides
      the GENERAL safety next for faulty developer analysis in all scenarios
      with a "constant <data type> not null := <vall> declaration."
    */
    mv        constant text            not null  := mv_in;
    m_and_ds           code.m_and_ds            := null;
  begin
    select
      m.v                          as master,
      array_agg(d.v order by d.v)  as details
    into strict m_and_ds
    from
      data.masters m
      left outer join
      data.details d
      using (mk)
    where m.v = mv
    group by 1
    order by 1;

    outcome_code := success;
    result := m_and_ds;

  exception when no_data_found then
    outcome_code := user_error;
    outcome_msg  := 'The master business key, "m", '''||mv||''' doesn''t exist.';
  end;
end;
$body$;

revoke all     on procedure code.do_master_and_details_report(text, code.m_and_ds, json_utils.outcome_codes, text) from public;
grant  execute on procedure code.do_master_and_details_report(text, code.m_and_ds, json_utils.outcome_codes, text) to   d2$json;
grant  execute on procedure code.do_master_and_details_report(text, code.m_and_ds, json_utils.outcome_codes, text) to   d2$qa;
