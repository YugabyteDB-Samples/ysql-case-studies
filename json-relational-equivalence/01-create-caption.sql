drop function if exists caption(text, text);
create function caption(t in text, mode in text = 'caption')
  returns table(z text)
  language plpgsql
as $body$
declare
  r1 constant text not null := rpad('=', 100, '=');
  r2 constant text not null := rpad('—', 100, '—');
begin
  case mode
    when 'caption' then
      z := r1;                                  return next;
      z := t;                                   return next;
      z := r1;                                  return next;

    when 'rule' then
      z := r2;                                  return next;
      z := t;                                   return next;
  end case;
end;
$body$;
