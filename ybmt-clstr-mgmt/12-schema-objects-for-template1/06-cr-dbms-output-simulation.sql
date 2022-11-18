create procedure mgr.output_buffer_flush()
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  flushed constant text not null := (array[null::text]::text[])::text;
begin
  execute format('set output.buffer to %L', flushed);
end;
$body$;

grant execute on procedure mgr.output_buffer_flush() to public;
--------------------------------------------------------------------------------

create procedure mgr.output_buffer_append_line(line in text)
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  flushed         constant text[] not null := array[null::text]::text[];
  current_buffer  constant text[] not null := current_setting('output.buffer')::text[];
  new_buffer      constant text[] not null :=
                    case
                      when (current_buffer = flushed) then (array[line]::text[])::text
                      else                                 (current_buffer||line)::text
                    end;
begin
  execute format('set output.buffer to %L', new_buffer);
end;
$body$;

grant execute on procedure mgr.output_buffer_append_line(text) to public;
--------------------------------------------------------------------------------

create function mgr.output_buffer_lines()
  returns table(z text)
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  buffer constant text[] not null := current_setting('output.buffer')::text[];
begin
  foreach z in array buffer loop
    return next;
  end loop;
end;
$body$;

grant execute on function mgr.output_buffer_lines() to public;
