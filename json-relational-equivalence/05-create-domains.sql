\t on
select caption('05-create-domains');
\t off

/*
——————————————————————————————————————————————————————————————————————————————————————————
  Notice that plain "name" collides with a system-supplied type.

  The names "given name" and "family name" are SQL names for the
  attributes of the composite types "t_name" and "a_name".
  They must be spelled this way to match the spellings of the names
  of the attributes of the JSON object that represents an author
  in the "authors" JSON array.

  "t_name" is used only in function "sql_authors(jsonb_nn)"
  in the invocation of jsonb_populate_record(null::t_name, ...).
  The target type must allow nulls to accommodate the
  formal requirement of this built-in.

  The domain "book_info_nn" is for use to hold incoming JSON documents (after typecasting
  to "jsonb") and to hold the output from "to_jsonb()" to convert from the relational
  representation, in SQL columns, to the the "jsonb" representation.
——————————————————————————————————————————————————————————————————————————————————————————
*/;

-- First, name the unconstrained built-in scalar data types to make it easier for
-- global search to find the (very few) occurrences.

drop domain  if exists  int_uc        cascade;
drop domain  if exists  boolean_uc    cascade;
drop domain  if exists  text_uc       cascade;
drop domain  if exists  jsonb_uc      cascade;

create domain           int_uc        as  int;
create domain           boolean_uc    as  boolean;
create domain           text_uc       as  text;
create domain           jsonb_uc      as  jsonb;
------------------------------------------------------------

drop domain  if exists  int_nn            cascade;
drop domain  if exists  boolean_nn        cascade;
drop domain  if exists  text_nn           cascade;
drop domain  if exists  jsonb_nn          cascade;
drop domain  if exists  book_info_nn      cascade;

drop domain  if exists  a_names_nn        cascade;
drop domain  if exists  a_name_nn         cascade;

drop type    if exists  t_name            cascade;
drop type    if exists  a_name            cascade;
drop type    if exists  book_info         cascade;

drop domain  if exists  j_books_keys_nn   cascade;
drop domain  if exists  key_facts_nn      cascade;
drop domain  if exists  key_facts_arr_nn  cascade;

drop type    if exists  j_books_keys      cascade;
drop type    if exists  key_facts         cascade;

create domain           int_nn            as  int        not null;
create domain           boolean_nn        as  boolean    not null;
create domain           text_nn           as  text       not null;
create domain           jsonb_nn          as  jsonb      not null;

create type             t_name            as (
  "given name"  text,
  "family name" text);

-- "given name" allows nulls
-- but "family name" doesn't.
create type             a_name            as (
  "given name"  text_uc,
  "family name" text_nn);

create domain           a_name_nn         as a_name  not null;
create domain           a_names_nn        as a_name[]      not null;

create type book_info                     as (
  isbn     text_nn,
  title    text_nn,
  year     int_nn,
  authors  a_names_nn,
  genre    text_uc);

create domain           book_info_nn      as book_info  not null;

create type             key_facts         as (key text_nn, data_type text_nn);
create domain           key_facts_nn      as key_facts not null;
create domain           key_facts_arr_nn  as key_facts[] not null;

create type j_books_keys as (
  isbn         key_facts_nn,
  title        key_facts_nn,
  year         key_facts_nn,
  authors      key_facts_nn,
  given_name   key_facts_nn,
  family_name  key_facts_nn,
  genre        key_facts_nn
);
create domain j_books_keys_nn             as j_books_keys not null;

----------------------------------------------------------------------------------------------------
/*
  Workaround needed for YB. (PG is OK.)
  See https://github.com/yugabyte/yugabyte-db/issues/12933

  Need the user-defined operator ||| just for YB 'cos it can't manage the
  implicit typecasting to evauate native concatenation here:

    « names::a_name[]||name::a_name »

  Search for ||| in "13-create-j-books-r-view-and-populate-r-books.sql".
*/;

drop operator if exists ||| (a_names_nn, a_name_nn)                   cascade;
drop function if exists a_names_concat_a_name(a_names_nn, a_name_nn)  cascade;

-- "left" and "right" are reserved words.
create function a_names_concat_a_name(L in a_names_nn, R in a_name_nn)
  returns a_names_nn
  language plpgsql
as $body$
declare
  result constant a_names_nn := L::a_name[]||R::a_name;
begin
  return result;
end;
$body$;

create operator ||| (
  leftarg   = a_names_nn,
  rightarg  = a_name_nn,
  procedure = a_names_concat_a_name);
