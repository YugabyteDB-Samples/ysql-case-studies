create function client_safe.rule_off(t in text, mode in text = 'level_1')
  returns table(z text)
  immutable
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  r1 constant text not null := rpad('=', 130, '=');
  r2 constant text not null := rpad('-', 120, '-');
begin
  case mode
    when 'level_1' then
      z := r1;                                  return next;
      z := t;                                   return next;
      z := r1;                                  return next;

    when 'level_2' then
      z := r2;                                  return next;
      z := rpad(('--- '||t||' '), 120, '-');    return next;
      z := '';                                  return next;

    when 'level_3' then
      z := rpad(('- - '||t||' '), 120, '- ');   return next;
  end case;
end;
$body$;

grant execute on function client_safe.rule_off(text, text) to public;

-- Multi-line variant for "level_3".
create function client_safe.rule_off(lines in text[])
  returns table(z text)
  immutable
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  t           text;
  r  constant text not null := rpad('-', 120, '-');
  lb constant int  not null := array_lower(lines, 1) + 1;
  ub constant int  not null := array_upper(lines, 1);
begin
  z := rpad(('- - '||lines[1]||' '), 120, '- ');                    return next;
  for j in lb..ub loop
    z := rpad(('    '||lines[j]||' '), 120, '- ');                  return next;
  end loop;
end;
$body$;

grant execute on function client_safe.rule_off(text[]) to public;
