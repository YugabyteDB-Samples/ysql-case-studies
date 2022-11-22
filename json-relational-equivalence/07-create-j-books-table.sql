\t on
select caption('07-create-j-books-table');
\t off
--------------------------------------------------------------------------------

drop table if exists j_books cascade;
create table j_books(
  k          integer
               generated always as identity primary key,
  book_info  jsonb_nn);
