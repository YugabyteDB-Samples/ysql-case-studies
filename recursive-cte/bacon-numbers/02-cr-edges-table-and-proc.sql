create table edges(
  node_1 text,
  node_2 text,
  movies text[],
  constraint edges_pk primary key(node_1, node_2),
  constraint edges_fk_1 foreign key(node_1) references actors(actor),
  constraint edges_fk_2 foreign key(node_2) references actors(actor));

create or replace procedure insert_edges()
  language plpgsql
as $body$
begin
  delete from edges;

  with
    v1(node_1, movie) as (
      select actor, movie from cast_members),

    v2(node_2, movie) as (
      select actor, movie from cast_members)

  insert into edges(node_1, node_2, movies)
  select node_1, node_2, array_agg(movie order by movie)
  from v1 inner join v2 using (movie)
  where node_1 < node_2
  group by node_1, node_2;

  insert into edges(node_1, node_2, movies)
  select node_2 as node_1, node_1 as node_2, movies
  from edges;
end;
$body$;
