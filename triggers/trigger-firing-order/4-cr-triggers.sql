create procedure u1.create_trigger(
  tg_table_name  in text,
  tg_when        in text,
  tg_level       in text)
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  ddl constant text not null := format(
    '
      create trigger %1$s_%2$s_%3$s
        %2$s insert or update or delete
        on u1.%1$I
        for each %3$s
      execute function u1.generic_trg()
    ',
    tg_table_name, tg_when, tg_level);
begin
  execute ddl;
end;
$body$;

--                      table      when      level

call u1.create_trigger('masters', 'before', 'statement');
call u1.create_trigger('masters', 'before', 'row'      );
call u1.create_trigger('masters', 'after',  'row'      );
call u1.create_trigger('masters', 'after',  'statement');

call u1.create_trigger('details', 'before', 'statement');
call u1.create_trigger('details', 'before', 'row'      );
call u1.create_trigger('details', 'after',  'row'      );
call u1.create_trigger('details', 'after',  'statement');
