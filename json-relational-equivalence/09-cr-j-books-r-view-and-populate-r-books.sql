\t on
select rule_off('09-cr-j-books-r-view-and-populate-r-books', 'level_3');
\t off
--------------------------------------------------------------------------------

deallocate all;

create function sql_authors(j in jsonb)
  returns a_name[]
  language plpgsql
as $body$
declare
  name   a_name   not null := ('', '');
  names  a_name[] not null := array[]::a_name[];

  last_idx constant int not null := (jsonb_array_length(j) - 1);
begin
  -- Self-doc. The function "j_books_book_info_is_conformant()" has already asserted this.
  assert jsonb_typeof(j) = 'array';

  for n in 0..last_idx loop
    name := jsonb_populate_record(null::a_name, (j->n));
    names := names||name;
  end loop;
  return names;
end;
$body$;

create view j_books_r_view(k, isbn, title, year, authors, genre) as
select
  k,
  (book_info->>'isbn')::text,
  (book_info->>'title')::text,
  (book_info->>'year')::int,
  (sql_authors(book_info->'authors')),
  book_info->>'genre'
from j_books;

-- WHICH SQL WOULD YOU PREFER TO EMBED IN YOUR APP'S CODE?

-- Alt. 1: Fashionable JSON.
prepare q5(text) as
select
  book_info->>'isbn'              as isbn,
  book_info->>'title'             as title,
  book_info-> 'authors'::text  as authors_jsonb_array
from j_books
where book_info->>'isbn' = $1;

execute q5('978-0-13-110362-7');
explain execute q5('978-0-13-110362-7');

-- Alt. 2: Good old SQL.
prepare q6(text) as
select
  isbn,
  title,
  authors::text as authors_sql_array
from j_books_r_view
where isbn = $1;

execute q6('978-0-13-110362-7');
explain execute q6('978-0-13-110362-7');

----------------------------------------------------------------------------------------------------
/*
  Create tables for the cassic 3NF representation of the information that
  the JSON book records represent, thus:

    genres    (k ... primary key, genre text not null)
    authors   (k ... primary key, given_name text, family_name text not null)

    r_books   (
                k           ...primary key,
                isbn        text not null unique,
                title       text not null,
                year        int not null,
                genre_k     int references genres(k)
              )

    bs_and_as (
                r_books_k   int not null,
                authors_k   int not null,
                pos         int not null,
                constraint  PK(r_books_k, authors_k)
              )
*/;

create table genres(
  k      integer
           generated always as identity primary key,
  genre  text not null);

create table authors(
  k            integer
                 generated always as identity primary key,
  given_name   text,
  family_name  text not null);

create unique index authors_full_name_unq on authors(coalesce(given_name, '<null>'), family_name);

-- Want to be able to "set r_books.k" manually when the table is first populated and then let the
-- sequence determine it for subsequent inserts. But once set, it's not allowed to change it.
-- So use "serial" with a trigger to prevent updating it- — and not "int generated always as identity".
create table r_books(
  k            serial primary key,
  isbn         text not null,
  title        text not null,
  year         int not null,
  genre_k      int references genres(k)

  -- Just for illustration. This should use the REGEXP approach that
  -- "j_books_book_info_is_conformant(()" implements
  constraint r_books_isbn_len_ok check(length(isbn) = 17));

create function trg_enforce_r_books_k_immutable()
  returns trigger
  language plpgsql
as $body$
begin
  assert false, 'Cannot update r_books.k';
  return null;
end;
$body$;

create trigger enforce_r_books_k_immutable
  after update
  on r_books
  for each row
  when (old.k != new.k)
execute procedure trg_enforce_r_books_k_immutable();

create index r_books_title_gin  on r_books using gin (to_tsvector('english', title));
create index r_books_year       on r_books(year);
create index r_books_genre_k    on r_books(genre_k);

-- Intersection table between "r_books" and "authors"
create table bs_and_as(
  r_books_k int not null,
  authors_k int not null,
  pos       int not null, 
  constraint bs_and_as_pk primary key(r_books_k, authors_k));

----------------------------------------------------------------------------------------------------
-- Populate the cassic 3NF representation from j_books_r_view.

-- Copy the relevant data from j_books_r_view to a throw-away table
-- so that it can be read and updated in successive steps.
create temp table r_books_temp(
  k                   int not null,
  isbn                text not null,
  title               text not null,
  year                int not null,
  author_given_name   text,
  author_family_name  text,
  pos                 int not null,
  genre               text,   
  genre_k             int);

insert into r_books_temp(k, isbn, title, year, pos,     author_given_name, author_family_name, genre)
select                   k, isbn, title, year, arr.pos, arr.given_name,    arr.family_name,    genre
from
  j_books_r_view
  cross join lateral
  unnest(authors) with ordinality as arr(given_name, family_name, pos)
order by k, pos;

insert into genres(genre)
select genre
from r_books_temp
where genre is not null
group by genre
order by genre;

select * from genres order by k;

update r_books_temp b
set genre_k = (
    select k from genres where genre = b.genre
  )
where genre is not null;

insert into r_books(k, isbn, title, year, genre_k)
select              k, isbn, title, year, genre_k
from r_books_temp
group by k, isbn, title, year, genre_k;

alter table r_books add constraint r_books_genre_k_fk
  foreign key(genre_k) references genres(k)
  match full
  on delete cascade;

insert into authors(given_name,        family_name       )
select              author_given_name, author_family_name
from r_books_temp
group by author_given_name, author_family_name
order by author_given_name, author_family_name;

select * from authors order by k;

-- Populate the intersection table.
-- This can doubltless be done more efficiently.
-- The point here is to make the logic maximally clear.
do $body$
declare
  b_k            int not null  := 0;
  b_pos          int not null  := 0;
  b_given_name   text;
  b_family_name  text := '';
  a_k            int not null  := 0;
begin
  for      b_k, b_pos, b_given_name,      b_family_name in (
    select k,   pos,   author_given_name, author_family_name
    from r_books_temp)
  loop
    select k
    into a_k
    from authors
    where
      given_name  is not distinct from b_given_name and
      family_name =                    b_family_name;

    insert into bs_and_as(r_books_k, authors_k, pos) values(b_k, a_k, b_pos);
  end loop;
end;
$body$;

select * from r_books order by k;

select * from bs_and_as order by r_books_k, authors_k, pos;

-- Finished!
----------------------------------------------------------------------------------------------------
-- Present the 3NF representation as a single relation with "authors" as a SQL array.

create view r_books_view(k, isbn, title, year, authors, genre) as
with
  c1(k, isbn, title, year, genre) as (
    select
      b.k,
      b.isbn,
      b.title,
      b.year,
      g.genre
    from
      r_books as b
      left outer join
      genres as g
      on (b.genre_k = g.k)
    ),

  c2(k, authors_k, pos) as (
    select
      b.k,
      i.authors_k,
      i.pos
    from
      r_books as b
      inner join
      bs_and_as as i
      on (b.k = i.r_books_k)
    ),

  c3(k, isbn, title, year, pos, authors_k, genre) as (
    select
      c1.k,
      c1.isbn,
      c1.title,
      c1.year,
      c2.pos,
      c2.authors_k,
      genre
    from
      c1
      inner join c2
      using(k)
    ),

  c4(k, isbn, title, year, pos, author, genre) as (
    select
      c3.k,
      c3.isbn,
      c3.title,
      c3.year,
      c3.pos,
      (a.given_name, a.family_name)::a_name, 
      c3.genre
    from
      c3
      inner join
      authors as a
      on (c3.authors_k = a.k)
    )

select
  k,
  isbn,
  title,
  year,
  array_agg(author order by pos),
  genre
from c4
group by k, isbn, title, year, genre;

select * from r_books_view order by k;
