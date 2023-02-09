create procedure trg_firing_order.create_trigger(
  tg_table_name  in text,
  tg_when        in text,
  tg_level       in text)
  security definer
  set search_path = pg_catalog, trg_firing_order, pg_temp
  language plpgsql
as $body$
declare
  ddl constant text not null := format(
    '
      create trigger %1$s_%2$s_%3$s
        %2$s insert or update or delete
        on %1$I
        for each %3$s
      execute function trg_firing_order.generic_trg()
    ',
    tg_table_name, tg_when, tg_level);
begin
  execute ddl;
end;
$body$;

--                      table      when      level

call trg_firing_order.create_trigger('masters', 'before', 'statement');
call trg_firing_order.create_trigger('masters', 'before', 'row'      );
call trg_firing_order.create_trigger('masters', 'after',  'row'      );
call trg_firing_order.create_trigger('masters', 'after',  'statement');

call trg_firing_order.create_trigger('details', 'before', 'statement');
call trg_firing_order.create_trigger('details', 'before', 'row'      );
call trg_firing_order.create_trigger('details', 'after',  'row'      );
call trg_firing_order.create_trigger('details', 'after',  'statement');
