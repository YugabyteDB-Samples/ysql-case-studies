create function cte_basics_proc.pure_sql_version(max_c1 in int)
  returns table(c1 int, c2 int)
  set search_path = pg_catalog, pg_temp
  language sql
as $body$
  with
    recursive r(c1, c2) as (

      -- Non-recursive term.
      (
        values (0, 1), (0, 2), (0, 3)
      )

      union all

      -- Recursive term.
      (
        select c1 + 1, c2 + 10
        from r
        where c1 < max_c1
      )
    )
  select c1, c2 from r order by c1, c2;
$body$;

select c1, c2 from cte_basics_proc.pure_sql_version(4) order by c1, c2;
