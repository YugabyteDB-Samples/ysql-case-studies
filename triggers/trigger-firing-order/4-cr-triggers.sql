create procedure create_trigger(
  tg_table_name  in text,
  tg_when        in text,
  tg_level       in text)
  security definer
  language plpgsql
as $body$
declare
  ddl constant text not null := format(
    '
      create trigger %1$s_%2$s_%3$s
        %2$s insert or update or delete
        on %1$I
        for each %3$s
      execute function generic_trg()
    ',
    tg_table_name, tg_when, tg_level);
begin
  execute ddl;
end;
$body$;

--                      table      when      level

call create_trigger('masters', 'before', 'statement');
call create_trigger('masters', 'before', 'row'      );
call create_trigger('masters', 'after',  'row'      );
call create_trigger('masters', 'after',  'statement');

call create_trigger('details', 'before', 'statement');
call create_trigger('details', 'before', 'row'      );
call create_trigger('details', 'after',  'row'      );
call create_trigger('details', 'after',  'statement');
