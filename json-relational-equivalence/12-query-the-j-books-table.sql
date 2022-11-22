\t on
select caption('12-query-the-j-books-table');
\t off
--------------------------------------------------------------------------------
-- Set up psql "colon-shortcuts" for the key names used here.
select title()
\gset k_

select year()
\gset k_

select authors()
\gset k_

select given_name()
\gset k_

select family_name()
\gset k_

--------------------------------------------------------------------------------
-- The k-v pairs in the book_info JSON object where v has a primitve datatype
-- allow queriues on the "raw" book_info to be expressed trivially and to take
-- advantage of ordinary indexes (undecorate, unique, partial, even GIN).
-- Here are some examples.

deallocate all;
-- Year
prepare q1(int_nn, int_nn) as
with c(year, title) as (
  select
    (book_info->>:k_year)::int_nn,
    book_info->>:k_title
  from j_books)
select year, title
from c
where year between $1 and $2
order by year, title;

execute q1(2000, 2008);
explain execute q1(2000, 2010);

-- Title
prepare q2(text_nn) as
select book_info->>:k_title as title
from j_books
where to_tsvector('english', book_info->>:k_title) @@ to_tsquery('english', $1);

execute q2('time');
execute q2('contrary');
explain execute q2('contrary');

--------------------------------------------------------------------------------
-- Querying for an author's "given name" or "family name" within the "authors" array
-- is hard. Do some research first and look at a couple of techniques.

-- This is no good for the "j_books" JSON schema.
with c(k, j) as (
  values
    (1, '["Jane", "Mary", "Fred"]'::jsonb_nn),
    (2, '["John", "Bill", "Suzy"]'::jsonb_nn)
  )
select
 k,
 j
from c
where j ? 'Mary';

-- This is no good either 'cos you can't generalize the approach to get *every*
-- "family name" value, given that "authors" might have any number of elements.
select
  k,
  (book_info->:k_authors->0)->>:k_family_name as first_author_family_name
from j_books
order by k;
/*
--------------------------------------------------------------------------------

  The approach uses the "boolean" expression:

    j1 @> j2

  i.e. the value j1 includes the (sub)value j2

  Here, the LHS array value:

    [
      {"given name": "Brian",  "family name": "Kernighan"},
      {"given name": "Dennis", "family name": "Ritchie"}
    ]

  includes this (sub)array value:

    ('[{"family name": "Kernighan"}]')::jsonb_nn

  In other words:

    select
      '
        [
          {"given name": "Brian",  "family name": "Kernighan"},
          {"given name": "Dennis", "family name": "Ritchie"}
        ]
      '::jsonb_nn
      @>
      '[{"family name": "Kernighan"}]'::jsonb_nn;

--------------------------------------------------------------------------------
*/;

-- It would be straightforward to extend the notion of the j_books_keys()
-- function with a variant that returns double-quoted key names for queries
-- like the ones that immediately follow this comment. Doing so would be useful
-- in real application code. But concatinating such values into the "text"
-- values that form the RHS for the @> operator would harm readability for
-- demo code like this.
--
-- This works!
select
  k,
  (book_info->:k_authors)::text_nn as authors
from j_books
where book_info->:k_authors @> '[{"family name": "Kernighan"}]'::jsonb_nn;

-- Counter-example: searching at the wrong level in the document tree.
select
  k,
  (book_info->:k_authors)::text_nn as authors
from j_books
where book_info @> ('{"family name": "Kernighan"}')::jsonb_nn;

-- Counter-counter-example (but you'd never do this):
select
  k,
  book_info
from j_books
where book_info @> ('{"authors": [{"given name": "Amy", "family name": "Tan"}]}')::jsonb_nn;

-- Use "prepare" to focus on the real test-value of interest.
prepare q3(text_nn) as
select
  k,
  (book_info->:k_authors)::text_nn as authors
from j_books
where book_info->:k_authors @> ('[{"family name": "'||$1||'"}]')::jsonb_nn
order by k;

-- There's a GIN index on book_info->:k_authors i.e. on a jsonb_nn value!
execute q3('Meadows');
execute q3('Sting');
explain execute q3('Sting');

--------------------------------------------------------------------------------
-- Finally, expand the "authors" array using jsonb_array_elements()
-- with CROSS JOIN LATERAL and WITH ORDINALITY.
drop view if exists v cascade;
create view v(k, title, pos, given_name, family_name) as
with
  c1 (k, title, pos, obj) as (
    select
      k,
      book_info->>:k_title,
      arr.pos,
      arr.obj
    from
    j_books
    cross join lateral
    jsonb_array_elements(book_info->:k_authors) with ordinality as arr(obj, pos))
select
  k,
  title,
  pos,
  obj->>:k_given_name,
  obj->>:k_family_name
from c1;

select
  k,
  title,
  pos,
  given_name,
  family_name
from v
where given_name is not null
order by k, pos;

prepare q4(text_nn) as
select
  k,
  title,
  pos,
  given_name,
  family_name
from v
where family_name = $1
order by k, pos;

\pset null '<NULL>'
execute q4('Sting');
\pset null ''

explain execute q4('Sting');
