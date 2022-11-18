create function fibonacci_series_cte(max_x in int)
  returns table(x int, f int)
  language sql
as $body$
  with
    recursive r(x, prev_f, f) as (
      values (1::int, 0::int, 1::int)

      union all

      select
        r.x + 1::int,
        r.f,
        r.f + r.prev_f
      from r
      where r.x < max_x
    )
  values(0, 0)
  union all
  select x, f from r;
$body$;

-- 0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144
select x, f as "fib(x)"
from fibonacci_series_cte(12)
order by x;
