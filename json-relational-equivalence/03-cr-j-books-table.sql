\t on
select client_safe.rule_off('03-cr-j-books-table', 'level_3');
\t off
--------------------------------------------------------------------------------

create table json.j_books(
  k          integer generated always as identity primary key,
  book_info  jsonb not null);
