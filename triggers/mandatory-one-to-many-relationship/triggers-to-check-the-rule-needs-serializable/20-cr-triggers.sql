call mgr.set_role('data');
/*
  Use the code for "raise_exception" in the "raise exception" statement thoughout.
  Use the message to express the actual problem.
*/;
--------------------------------------------------------------------------------
-- HELPER SUBPROGRAMS
/*
  It's critical that "set_cascade_delete_flag()" is "security invoker".
  This ensures that it can be called ONLY when the invoking role is "data",
  because only "data" has the "temporary" privilege on the database "play".

  And the invoking role as WILL be "data" when "set_cascade_delete_flag()"
  is called from the trigger function "call_set_cascade_delete_flag()"
  on these triggers:

    "data.set_cascade_delete_flag_on_masters"
    "data.set_cascade_delete_flag_on_details"

  It's good practice to set function "cascade_delete_flag()" to "security invoker"
  too.
*/;
create procedure data.set_cascade_delete_flag(mode_in in boolean)
  security invoker
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  mode constant boolean not null := mode_in;
  msg           text    not null := '';
begin
  create temporary table if not exists cascade_delete_flag(val boolean not null) on commit delete rows;
  case mode
    when false then
      delete from pg_temp.cascade_delete_flag;
    when true then
      insert into pg_temp.cascade_delete_flag(val) values(true);
  end case;
end;
$body$;
call mgr.revoke_all_from_public('procedure', 'data.set_cascade_delete_flag(boolean)');
call mgr.grant_priv( 'execute', 'procedure', 'data.set_cascade_delete_flag(boolean)', 'client');

create function data.cascade_delete_flag()
  returns boolean
  stable
  security invoker
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  val  boolean not null := false;
  msg  text    not null := '';
begin
  -- No action needed if "pg_temp.cascade_delete_flag" doesn't (yet) exist
  -- because this is taken to mean that the flag is FALSE.
  begin
    val := exists (select 1 from pg_temp.cascade_delete_flag);
  exception when undefined_table then
    get stacked diagnostics msg = message_text;
    if msg != 'relation "pg_temp.cascade_delete_flag" does not exist' then
      raise;
    end if;
  end;
  return val;
end;
$body$;
call mgr.revoke_all_from_public('function', 'data.cascade_delete_flag()');

create procedure data.assert_iso_lvl_is_serializable()
  security invoker
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  lvl constant text not null := current_setting('transaction_isolation');
begin
  if lvl <> 'serializable' then
    raise exception
      'You must use the serializable isolation level'
      using errcode = 'P0001';
  end if;
end;
$body$;
call mgr.revoke_all_from_public('procedure', 'data.assert_iso_lvl_is_serializable()');
--------------------------------------------------------------------------------
/*
  Common good practice: enforce that values for all PK and FK columns
  (or column lists, in general) are immutable.
*/;
create function data.enforce_masters_mk_immutable()
  returns trigger
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
begin
  raise exception
    '"masters.mk" is immutable.'
    using errcode = 'P0001';
  return null;
end;
$body$;
call mgr.revoke_all_from_public('function', 'data.enforce_masters_mk_immutable()');

create trigger enforce_masters_mk_immutable
  after update
  on data.masters
  for each row
  when (new.mk != old.mk)
  execute function data.enforce_masters_mk_immutable();

create function data.enforce_details_dk_mk_immutable()
  returns trigger
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
begin
  raise exception
    '"details.dk" and "details.mk" are immutable.'
    using errcode = 'P0001';
  return null;
end;
$body$;
call mgr.revoke_all_from_public('function', 'data.enforce_details_dk_mk_immutable()');

create trigger enforce_details_dk_mk_immutable
  after update
  on data.details
  for each row
  when ((new.dk != old.dk) or (new.mk != old.mk))
  execute function data.enforce_details_dk_mk_immutable();
--------------------------------------------------------------------------------
/*
  Scheme to ensure that "enforce_mdry_1_to_m_rule_for_details"
  skips its test when all "detail" rows for a particular "masters" row are to be
  "cascade deleted" as a consequence of deleting that "masters" row.

  It relies on these two triggers:
    "before delete on masters for each row",
    "after  delete on details for each statement".

  Each of them calls the same "set_cascade_delete_flag()" trigger function. The
  TRUE/FALSE flag status is represented using the temporary table "cascade_delete_flag",
  thus:

    TRUE:
       "cascade_delete_flag" exists and has at least one row.

    FALSE:
      EITHER "cascade_delete_flag" exists and is empty;
      OR:    "cascade_delete_flag" does not exist.

  The function "cascade_delete_flag()" returns the current flag status.
  The procedure "set_cascade_delete_flag()" sets the status and, if
  the "cascade_delete_flag" table doesn't yet exists, it creates it.
*/;

create function data.call_set_cascade_delete_flag()
  returns trigger
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
begin
  case tg_relname::text 
    when 'masters' then
      /*
        Cascade delete (i.e. deleting a "masters" row and of all its "details" rows
        must succeed. (Else, inserting a new "masters" row will be a "write once,
        never detes" operation.)

        It seems that the implementation identfies each to-be-deleted "masters" row.
        then deletes all of this rows "details" row, and only then deletes the
        present to-be-deleted "masters" row. Without this approach, the "details_fk"
         would be violated.

        Therefore deleting a "masters" row must be hand;ed as a special case by
        bypassing the usual test that deleting "details" rows for a given "masters" row
        must leaves at least one "details" row in place.

        The "cascade delete flag" flag allows this.
      */
      declare
        masters_not_empty constant boolean not null :=
          exists (select 1 from data.masters);
      begin
        case masters_not_empty
          when true then
            call data.set_cascade_delete_flag(true);
          else
            call data.set_cascade_delete_flag(false);
        end case; 
      end;
    when 'details' then
      call data.set_cascade_delete_flag(false);
  end case;
  return old;
end;
$body$;
call mgr.revoke_all_from_public('function', 'data.call_set_cascade_delete_flag()');

--/*
create trigger set_cascade_delete_flag_on_masters
  before delete
  on data.masters
  for each statement
  execute function data.call_set_cascade_delete_flag();

create trigger set_cascade_delete_flag_on_details
  after delete
  on data.details
  for each statement
  execute function data.call_set_cascade_delete_flag();
--*/
-------------------------------------------------------------------------------
/*
  The key triggers:
    "after insert on masters for each row"
    "after delete on details for each row"
  to enforce the "madatory-one-to=many" rule.

  Notice that each uses the same test:

    ok constant boolean not null :=
      exists (select 1 from data.details d where d.mk = %);

 where % is new.mk (from "masters") or old.com (from "details").
*/;

create function data.enforce_mdry_1_to_m_rule_for_masters()
  returns trigger
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  ok constant boolean not null :=
    exists (select 1 from data.details d where d.mk = new.mk);
begin
  if not ok then
    raise exception
      'Inserting new master: each master must have at least one detail.'
      using errcode = 'P0001';
  end if;
  return new;
end;
$body$;
call mgr.revoke_all_from_public('function', 'data.enforce_mdry_1_to_m_rule_for_masters()');

create trigger enforce_mdry_1_to_m_rule_for_masters
  after insert
  on data.masters
  for each row
execute function data.enforce_mdry_1_to_m_rule_for_masters();

create function data.enforce_mdry_1_to_m_rule_for_details()
  returns trigger
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  ok constant boolean not null :=
    exists (select 1 from data.details d where d.mk = old.mk);
begin
  if not data.cascade_delete_flag() then
    -- This logic depends on using the serializable isolation level.
    call data.assert_iso_lvl_is_serializable();
    if not ok then
      raise exception
        'Deleting a detail: each master must have at least one detail.'
        using errcode = 'P0001';
    end if;
  end if;
  return null;
end;
$body$;
call mgr.revoke_all_from_public('function', 'data.enforce_mdry_1_to_m_rule_for_details()');

create trigger enforce_mdry_1_to_m_rule_for_details
  after delete
  on data.details
  for each row
execute function data.enforce_mdry_1_to_m_rule_for_details();
