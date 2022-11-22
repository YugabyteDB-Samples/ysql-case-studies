:u1
:c

create procedure set_cascade_delete_flag(mode_in in boolean)
  language plpgsql
as $body$
declare
  mode constant boolean not null := mode_in;
  msg           text    not null := '';
begin
  case mode
    when false then
      -- No action needed if "cascade_delete_flag" doesn't (yet) exist
      -- because this is taken to mean that the falg is FALSE.
      begin
        delete from cascade_delete_flag;
      exception when undefined_table then
        get stacked diagnostics msg = message_text;
        if msg != 'relation "cascade_delete_flag" does not exist' then
          raise;
        end if;
      end;

    when true then
      begin
        insert into cascade_delete_flag(val) values(true);
      exception when undefined_table then
        get stacked diagnostics msg = message_text;
        if msg != 'relation "cascade_delete_flag" does not exist' then
          raise;
        else
          create temp table cascade_delete_flag(val boolean not null) on commit delete rows;
          insert into cascade_delete_flag(val) values(true);
        end if;
      end;
  end case;
end;
$body$;

create function cascade_delete_flag()
  returns boolean
  language plpgsql
as $body$
declare
  val  boolean not null := false;
  msg  text    not null := '';
begin
  -- No action needed if "cascade_delete_flag" doesn't (yet) exist
  -- because this is taken to mean that the falg is FALSE.
  begin
    val := exists (select 1 from cascade_delete_flag);
  exception when undefined_table then
    get stacked diagnostics msg = message_text;
    if msg != 'relation "cascade_delete_flag" does not exist' then
      raise;
    end if;
  end;
  return val;
end;
$body$;

create procedure test(mode_in in boolean, result out text)
  language plpgsql
as $body$
declare
  mode constant boolean not null := mode_in;
begin
  call set_cascade_delete_flag(mode);
  result := cascade_delete_flag();
end;
$body$;

/*
drop table if exists cascade_delete_flag cascade;
call test(false, ''::text);
\d cascade_delete_flag

call test(true, ''::text);
\d cascade_delete_flag

drop table cascade_delete_flag cascade;
call test(true, ''::text);
\d cascade_delete_flag
*/;

-- DOES IT WORK FROM A TRIGGER?

create table t(k serial primary key, v text not null);
insert into t(v) values('dog');

create function t_trg_before()
  returns trigger
  language plpgsql
as $body$
begin
  call set_cascade_delete_flag(true);
  return old;
end;
$body$;

create trigger t_trg_before
  before delete
  on t
  for each statement
  execute function t_trg_before();

\d cascade_delete_flag
delete from t;
\d cascade_delete_flag
