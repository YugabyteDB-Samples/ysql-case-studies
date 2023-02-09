\t on
select client_safe.rule_off('01-cr-types', 'level_3');
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
create type json.a_name as (
  "given name"  text,
  "family name" text);

create type json.book_info as (
  isbn     text,
  title    text,
  year     int,
  authors  json.a_name[],
  genre    text);

create type json.key_facts as (key text, data_type text);

create type json.j_books_keys as (
  isbn         json.key_facts,
  title        json.key_facts,
  year         json.key_facts,
  authors      json.key_facts,
  given_name   json.key_facts,
  family_name  json.key_facts,
  genre        json.key_facts
);
