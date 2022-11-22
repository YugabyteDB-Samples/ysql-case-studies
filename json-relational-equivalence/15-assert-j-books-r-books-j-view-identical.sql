\t on
select caption('15-assert-j-books-r-books-j-view-identical');
\t off
--------------------------------------------------------------------------------

do $body$
declare
  differ constant boolean_nn :=
    (
    with
      a as (select * from j_books except select * from r_books_j_view),
      b as (select * from r_books_j_view except select * from j_books)
    select (exists(select 1 from a) or exists(select 1 from b))
    );
begin
  assert not differ, '"j_books" versus "r_books_j_view" test failed';
end;
$body$;
