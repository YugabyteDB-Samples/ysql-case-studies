-- Classic text-book demo of recursive function invocation.
create function cte_basics_fib.fib(n in int)
  returns int
  set search_path = pg_catalog, cte_basics_fib, pg_temp
  language plpgsql
as $body$
declare
  -- Use these constants to be 100% sure that there's no datatype conversion.
  zero constant integer not null := 0;
  one  constant integer not null := 1;
  two  constant integer not null := 2;
begin
  if n < one then
    return zero;
  elsif n = one then
    return one;
  else
    return fib(n - one) + fib(n - two);
  end if;
end;
$body$;

create function cte_basics_fib.fibonacci_series(max_x in int)
  returns table(x int, f int)
  set search_path = pg_catalog, cte_basics_fib, pg_temp
  language plpgsql
as $body$
begin
  for j in 0..max_x loop
    x := j; f := fib(j); return next;
  end loop;
end;
$body$;

-- 0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144
select x, f as "fib(x)" from cte_basics_fib.fibonacci_series(12);

drop function if exists fibonacci_series(int) cascade;

-- Ordinary iterative implementation of "fibonacci_series()"
create function cte_basics_fib.fibonacci_series_plpgsql(max_x in int)
  returns table(x int, f int)
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  prev_f       int not null := -1;
  prev_prev_f  int not null := -1;
begin
  x := 0; f := 0;                               return next;
  prev_prev_f := f;

  x := 1; f := 1;                               return next;
  prev_f := f;
 
  for j in 2..max_x loop
    x := j; f := prev_prev_f + prev_f;          return next;
    prev_prev_f := prev_f;
    prev_f := f;
  end loop;
end;
$body$;

select x, f as "fib(x)" from cte_basics_fib.fibonacci_series_plpgsql(12);
