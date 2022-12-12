create function list_paths(tab in text)
  returns table(t text)
  language plpgsql
as $body$
declare
  -- Recall that when you address an array element that falls outside of its bounds,
  -- you get a `NULL` result. And recall that `NULLS FIRST` is the default sorting order.
  stmt constant text := $$
    with a(r, c, p) as (
      select
        row_number() over w,
        cardinality(path),
        path
      from ?
      window w as
        (order by path[1], cardinality(path), path[2], path[3], path[4], path[5], path[6]))

    select
      array_agg(
        lpad(r::text,  6) ||'   '||
        lpad(c::text, 11) ||'   '||
        replace(translate(p::text, '{"}', ''), ',', ' > ')
        order by p[1], cardinality(p), p[2], p[3], p[4], p[5], p[6])
    from a
    $$;

  results text[] not null := '{}';
begin
  t := 'path #   cardinality   path'; return next;
  t := '------   -----------   ----'; return next;

  execute replace(stmt, '?', tab) into results;
  foreach t in array results loop
    return next;
  end loop;
end;
$body$;
