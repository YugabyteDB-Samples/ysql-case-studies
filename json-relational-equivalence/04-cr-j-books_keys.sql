\t on
select rule_off('04-cr-j-books_keys', 'level_3');
\t off
--------------------------------------------------------------------------------
-- HERE IS THE SINGLE POINT OF DEFINITION FOR THE NAMES AND DATATYPES OF THE BOOKS KEYS.
-- We need to be able to map a SQL or PL/pgSQL identifer to a name, so we need to
-- use a composite type.

create function j_books_keys()
  returns j_books_keys
  language plpgsql
as $body$
declare
  number_t constant text not null := 'number';
  string_t constant text not null := 'string';
  array_t  constant text not null := 'array';

  ks j_books_keys;
begin
  -- Notice that the "genre" key and the "given name" key are optional. But the
  -- (informal) JSON Schema says that if either is present, then it cannot have
  -- the value « JSON null ».

  ks.isbn        := ('isbn',        string_t);
  ks.title       := ('title',       string_t);
  ks.year        := ('year',        number_t);
  ks.authors     := ('authors',     array_t);
  ks.given_name  := ('given name',  string_t);
  ks.family_name := ('family name', string_t);
  ks.genre       := ('genre',       string_t);

  return ks;
end;
$body$;
------------------------------------------------------------------------------------------

create function top_level_keys()
  returns key_facts[]
  language plpgsql
  immutable
as $body$
declare
  ks constant j_books_keys not null := j_books_keys();

  isbn     constant text not null := (ks.isbn)    .key;
  title    constant text not null := (ks.title)   .key;
  year     constant text not null := (ks.year)    .key;
  authors  constant text not null := (ks.authors) .key;
  genre    constant text not null := (ks.genre)   .key;

  kvs constant key_facts[] not null :=
    array[
      (isbn,     'string'),
      (title,    'string'),
      (year,     'number'),
      (authors,  'array'),
      (genre,    'string')
    ];
begin
  return kvs;
end;
$body$;

create function author_keys()
  returns key_facts[]
  language plpgsql
  immutable
as $body$
declare
  ks constant j_books_keys not null := j_books_keys();

  given_name   constant text not null := (ks.given_name)  .key;
  family_name  constant text not null := (ks.family_name) .key;

  kvs constant key_facts[] not null :=
    array[
      (given_name,  'string'),
      (family_name, 'string')
    ];
begin
  return kvs;
end;
$body$;
------------------------------------------------------------------------------------------
/*
  These functions are for ad-hoc SQL queries in psql or ysqlsh. Use them to avoid the risk
  of typo'ing a key name by setting upl "colon-shortcuts" for the key names that you want.
  Look at the SQL that implements each function. It's too tricky for human use.
  So hide each in a "language sql" function. Use them like this:

    select title()
    \gset k_
*/;

create function title()
  returns text
  language sql
as $body$
  select (''''||((j_books_keys()).title).key||'''')::text;
$body$;

create function isbn()
  returns text
  language sql
as $body$
  select (''''||((j_books_keys()).isbn).key||'''')::text;
$body$;

create function year()
  returns text
  language sql
as $body$
  select (''''||((j_books_keys()).year).key||'''')::text;
$body$;

create function authors()
  returns text
  language sql
as $body$
  select (''''||((j_books_keys()).authors).key||'''')::text;
$body$;

create function genre()
  returns text
  language sql
as $body$
  select (''''||((j_books_keys()).genre).key||'''')::text;
$body$;

create function given_name()
  returns text
  language sql
as $body$
  select (''''||((j_books_keys()).given_name).key||'''')::text;
$body$;

create function family_name()
  returns text
  language sql
as $body$
  select (''''||((j_books_keys()).family_name).key||'''')::text;
$body$;

------------------------------------------------------------------------------------------
-- TESTS/DEMOS

-- This simply lists out what "j_books_keys()" defines in a user-friendly fashion.
-- It isn't used outside of this file.

create function j_books_keys_list()
  returns table(z text)
  language plpgsql
as $body$
declare
  ks j_books_keys not null := j_books_keys();
begin
  z := rpad((ks.isbn)        .key, 13)||(ks.isbn)        .data_type;          return next;
  z := rpad((ks.title)       .key, 13)||(ks.title)       .data_type;          return next;
  z := rpad((ks.year)        .key, 13)||(ks.year)        .data_type;          return next;
  z := rpad((ks.authors)     .key, 13)||(ks.authors)     .data_type;          return next;
  z := rpad((ks.given_name)  .key, 13)||(ks.given_name)  .data_type;          return next;
  z := rpad((ks.family_name) .key, 13)||(ks.family_name) .data_type;          return next;
  z := rpad((ks.genre)       .key, 13)||(ks.genre)       .data_type;          return next;
end;
$body$;

select j_books_keys_list() as "all keys and their data types";

create function top_level_keys_list()
  returns table(z text)
  language plpgsql
as $body$
declare
  kvs  constant key_facts[] not null := top_level_keys();
  kv            key_facts   not null  := ('', '');
begin
  foreach kv in array kvs loop
    z := rpad(kv.key, 13)||kv.data_type;          return next;
  end loop;
end;
$body$;

select top_level_keys_list() as "top-level keys and their data types";

create function author_keys_list()
  returns table(z text)
  language plpgsql
as $body$
declare
  kvs  constant key_facts[] not null := author_keys();
  kv            key_facts   not null  := ('', '');
begin
  foreach kv in array kvs loop
    z := rpad(kv.key, 13)||kv.data_type;          return next;
  end loop;
end;
$body$;

select author_keys_list() as "author keys and their data types";
