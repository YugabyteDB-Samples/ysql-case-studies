\t on
select rule_off('01-cr-types', 'level_3');
\t off

/*
——————————————————————————————————————————————————————————————————————————————————————————
  Notice that plain "name" collides with a system-supplied type.

  The names "given name" and "family name" are SQL names for the
  attributes of the composite type "a_name".
  They must be spelled this way to match the spellings of the names
  of the attributes of the JSON object that represents an author
  in the "authors" JSON array.

  The type "book_info" is for use to hold incoming JSON documents (after typecasting
  to "jsonb") and to hold the output from "to_jsonb()" to convert from the relational
  representation, in SQL columns, to the the "jsonb" representation.
——————————————————————————————————————————————————————————————————————————————————————————
*/;

-- Notice that "given name" allows nulls but "family name" doesn't.
create type a_name as (
  "given name"  text,
  "family name" text);

create type book_info as (
  isbn     text,
  title    text,
  year     int,
  authors  a_name[],
  genre    text);

create type key_facts as (key text, data_type text);

create type j_books_keys as (
  isbn         key_facts,
  title        key_facts,
  year         key_facts,
  authors      key_facts,
  given_name   key_facts,
  family_name  key_facts,
  genre        key_facts
);
