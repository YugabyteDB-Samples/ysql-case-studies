call bacon.insert_edges();

with v(actor) as (
  select node_1 from bacon.edges
  union
  select node_2 from bacon.edges)
select actor from v order by 1
limit 10;

select distinct unnest(movies) as movie
from bacon.edges
order by 1
limit 10;

select
  node_1,
  node_2,
  replace(translate(movies::text, '{"}', ''), ',', ' | ') as movies
from bacon.edges
where node_1 < node_2
order by 1, 2
limit 10;

select
  node_1,
  node_2,
  replace(translate(movies::text, '{"}', ''), ',', ' | ') as movies
from bacon.edges
where node_1 > node_2
order by 2, 1
limit 10;
