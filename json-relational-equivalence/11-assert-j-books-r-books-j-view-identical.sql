\t on
select client_safe.rule_off('15-assert-j-books-r-books-j-view-identical', 'level_3');
\t off
--------------------------------------------------------------------------------

do $body$
declare
  differ constant boolean not null :=
    (
    with
      a as (select * from json.j_books except select * from json.r_books_j_view),
      b as (select * from json.r_books_j_view except select * from json.j_books)
    select (exists(select 1 from a) or exists(select 1 from b))
    );
begin
  assert not differ, '"j_books" versus "r_books_j_view" test failed';
end;
$body$;
