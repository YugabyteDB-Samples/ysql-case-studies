with v(actor) as (
  select node_1 from edges
  union
  select node_2 from edges)
select actor from v order by 1;

select distinct unnest(movies) as movie
from edges
order by 1;

-- node_1 < node_2
select
  node_1,
  node_2,
  replace(translate(movies::text, '{"}', ''), ',', ' | ')  as movies
from edges
where node_1 < node_2
order by 1, 2;

/*
  NOTICE THAT EVERY EDGE IS REPRESENTED TWICE, ONCE IN EACH DIRECTION.

  -- node_1 > node_2
  select
    node_1,
    node_2,
    replace(translate(movies::text, '{"}', ''), ',', ' | ')  as movies
  from edges
  where node_1 > node_2
  order by 2, 1;
*/;
