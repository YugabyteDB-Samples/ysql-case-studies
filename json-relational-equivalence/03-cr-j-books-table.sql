\t on
select rule_off('03-cr-j-books-table');
\t off
--------------------------------------------------------------------------------

create table j_books(
  k          integer generated always as identity primary key,
  book_info  jsonb not null);