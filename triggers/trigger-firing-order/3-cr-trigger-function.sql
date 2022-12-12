create function generic_trg()
  returns trigger
  security definer
  language plpgsql
as $body$
declare
  v constant text not null :=
    case lower(tg_op||'~'||tg_level)

      when 'insert~statement'  then ''
      when 'update~statement'  then ''
      when 'delete~statement'  then ''

      when 'insert~row'        then new.v
      when 'update~row'        then new.v
      when 'delete~row'        then old.v

    end;
begin
  call log_a_firing(tg_when, tg_op, tg_table_name, tg_level, v);
  return
    case lower(tg_op)
      when 'insert'  then new
      when 'update'  then new
      when 'delete'  then old
    end;
end;
$body$;
