create table trigger_firings(
  k              serial primary key,
  tg_when        text   not null,
  tg_op          text   not null default '',
  tg_table_name  text   not null default '',
  tg_level       text   not null default '',
  v              text   not null default '',
  tg_name        text   not null default '');
--------------------------------------------------------------------------------

create procedure log_a_firing(
  tg_when        in text,
  tg_op          in text = '',
  tg_table_name  in text = '',
  tg_level       in text = '',
  v              in text = '',
  tg_name        in text = '')

  security definer
  language plpgsql
as $body$
begin
  if (tg_when = '') then
    -- Blank line for readility.
    insert into trigger_firings
      (tg_when, tg_op, tg_table_name, tg_level, v, tg_name)
    values
      ('', '', '', '', '', '', '');
  else
    insert into trigger_firings
      (tg_when, tg_op, tg_table_name, tg_level, v, tg_name)
    values
      (tg_when, tg_op, tg_table_name, tg_level, v, tg_name);
  end if;
end;
$body$;
--------------------------------------------------------------------------------

create procedure log_a_constraint_check(v in text, constraint_fn in text)
  security definer
  language plpgsql
as $body$
begin
  insert into trigger_firings
    (tg_when, tg_op, tg_table_name, tg_level, v, tg_name)
  values
    ('check', '', '', '', v, constraint_fn);
end;
$body$;
--------------------------------------------------------------------------------

create procedure log_a_comment(t in text = '')
  security definer
  language plpgsql
as $body$
begin
  insert into trigger_firings(tg_when) values ('-'), (''), ('-- '||t);
end;
$body$;
--------------------------------------------------------------------------------

-- Produce a nicely readable report from the raw contents of "trigger_firings".
create function trigger_firings()
  returns table(z text)
  stable
  security definer
  language plpgsql
as $body$
declare
  tg_when_          text not null := '';
  tg_op_            text not null := '';
  tg_table_name_    text not null := '';
  tg_level_         text not null := '';
  v_                text not null := '';
  tg_name_          text not null := '';

  last_table_name_  text not null := '';
begin
  for 
    tg_when_,
    tg_op_,
    tg_table_name_,
    tg_level_,
    v_,
    tg_name_
  in
    (
      select
        case tg_when
          when 'AFTER'  then 'after'
          when 'BEFORE' then 'before'
          else               tg_when
        end,
        lower(tg_op),
        tg_table_name,
        lower(tg_level),
        v,
        tg_name
      from trigger_firings
      order by k
    )
  loop
    declare
      test constant boolean not null := tg_op_ = ''         and
                                        tg_table_name_ = '' and
                                        tg_level_ = ''      and
                                        v_ = ''             and
                                        tg_name_ = '';
    begin
      -- Avoid spurious blank lines before and after the line
      -- for the row that log_a_constraint_check() inserts.
      if tg_when_ = 'check' then
          tg_table_name_ := last_table_name_;
      end if;

      -- Improve the report's readability.
      if tg_table_name_ <> last_table_name_ then
        z := '';                                                    return next;
      end if;
      last_table_name_ := tg_table_name_;

      z := case
             when tg_when_ = 'check' then
               'check'||rpad(' ',   41)||
               '  >  '                 ||
               rpad(v_,              9)||
               tg_name_

             when tg_when_ = ''  and test then
               ''

             when tg_when_ <> '' and test then
               case
                 when tg_when_ = '-' then rpad('-', 80, '-')
                 else                     tg_when_
               end

             else
               rpad(tg_when_,        7)||
               rpad(tg_op_,          7)||
               'on '                   ||
               rpad(tg_table_name_, 11)||
               'for each '             ||
               rpad(tg_level_,       9)||
               '  >  '                 ||
               rpad(v_,              9)||
               tg_name_
           end;                                                     return next;
    end;
  end loop;
end;
$body$;
