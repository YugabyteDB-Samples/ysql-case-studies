set role d4$code;
grant usage on schema code to d4$client;

create type code.m_and_ds as (m  text, ds text[]);
revoke all   on type code.m_and_ds from public;
grant  usage on type code.m_and_ds to   d4$client;

create procedure code.insert_master_and_details(
  m_and_ds in code.m_and_ds)
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  new_mk int not null := nextval('data.masters_mk_seq'::regclass)*100;
  new_dk int not null := nextval('data.details_dk_seq'::regclass);

  mv     text    not null := '';
  dv     text    not null := '';
  first  boolean not null := true;

  stmt   text    not null := '';
begin
  insert into data.masters(mk, dk, v) values(new_mk, new_dk, m_and_ds.m);

  foreach dv in array m_and_ds.ds loop
     case first
       when true then
          insert into data.details(dk, mk, v) values(new_dk, new_mk, dv);
          first := false;

       when false then
          -- use generated values from now on
          insert into data.details(dk, mk, v) values(nextval('data.details_dk_seq'::regclass), new_mk, dv);
     end case;
  end loop;
end;
$body$;
revoke all     on procedure code.insert_master_and_details(code.m_and_ds) from public;
grant  execute on procedure code.insert_master_and_details(code.m_and_ds) to   d4$client;
--------------------------------------------------------------------------------

create procedure code.cascade_delete_specified_masters(mvs variadic text[] = null)
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
begin
  case
    when mvs is null then
      delete from data.masters;
    else
      delete from data.masters where v = any(mvs);
  end case;
end;
$body$;
revoke all     on procedure code.cascade_delete_specified_masters(text[]) from public;
grant  execute on procedure code.cascade_delete_specified_masters(text[]) to   d4$client;

--------------------------------------------------------------------------------
/*
  Deleting a "details" row is the only case that might lead to constraint
  violation. So only this needs to deal with the foreign_key_violation" error.

  Notice that the mutual FKs between a given "masters" row and its presently
  special "details" row is sufficient to guarantee that the mandatory
  "one-to-many" rule holds.

  The "twizzle" that the trigger "details_after_statement" implements
  avoids a spurious FK violation error on deleting the presently special
  "details" row  until you're down to a single surviving "details" row.
  Attempting to delete this must then cause the FK violation error to
  honor the rule.

  Without locking the siblings of each to-be-deleted "details" row, you
  risk getting the FK violation error in a race condition where, without
  the race, you wouldn't. In other words, the locking improves usability
  but plays no part in enforcing the rule.
*/;
create procedure code.delete_specified_details(outcome inout text, dvs variadic text[] = null)
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  detail text not null := '';
  d      text not null := '';
begin
  case
    when dvs is null then
      null;
    else
      -- Lock the all siblings of each to-be-deleted "details" row.
      foreach d in array dvs loop
         declare
           mk_  constant int          := (select mk from data.details where v = d);
           dk_           int not null := 0;
         begin
           for dk_ in (select dk from data.details where mk = mk_ for update) loop
             null;
           end loop;
         end;
      end loop;
      delete from data.details where v = any(dvs);
  end case;
  /*
    Bring the error forward to allow it to be handled in PL/pgSQL. (This is
    race-condition safe for a native constraint like FK.)

   This works reliably only in PG. In YB, it works as long as the deferred FK rule _can_ be satisfied.
   But when it _cannot_ be satisfied, then "set constraints all immediate" doesn't cause the intended
   ordinary FK violation error. Rather, it causes a run-time server crash, thus:

    server closed the connection unexpectedly
    This probably means the server terminated abnormally
    before or while processing the request.
    The connection to the server was lost. Attempting reset: Succeeded.

  This error has no code and cannot be caught in PL/pgSQL code. It inevitably leaks to the client
  where it invites submitting a complaint to Support. The better alternative is not tu use the erroring
  statement but, rather, let the FK violation error be detected at commit time. This is still unsatisfactory
  because it, too, cannot be caught in PL/pgSQL code and therefore leaks to the client. But this is better
  than a report of a server crash.
  */

  if version() not like '%YB%' then
    set constraints all immediate;
  end if;
  outcome := 'Success.';
exception
  -- This handler won't catch anything in YB.
  when foreign_key_violation then
    
    get stacked diagnostics detail = pg_exception_detail;
    outcome := 'User error: cannot delete a master''s last surviving detail.'||chr(10)||
               '            '||detail;
end;
$body$;
revoke all     on procedure code.delete_specified_details(text, text[]) from public;
grant  execute on procedure code.delete_specified_details(text, text[]) to   d4$client;
