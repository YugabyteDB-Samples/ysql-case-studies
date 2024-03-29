\t on
select client_safe.rule_off('10-cr-r-books-j-view', 'level_3');
\t off
--------------------------------------------------------------------------------

create view json.r_books_j_view(k, book_info)
as

  /*
    Notice "jsonb_strip_nulls()". This is essential because "to_jsonb()"
    generates « "my_key": null » patterns. The informal JSON Schema for books
    always represents this "value" by the absence of "my_key".
  */

select k, jsonb_strip_nulls(to_jsonb((isbn, title, year, authors, genre)::json.book_info))
from json.r_books_view;

\t on
select k, jsonb_pretty(book_info)
from json.r_books_j_view
order by k;
\t off
