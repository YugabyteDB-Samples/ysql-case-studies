\t on
select caption('06-create-detect-and-strip-null-keys');
\t off

/*
——————————————————————————————————————————————————————————————————————————————————————————

  The informally expressed JSON Schema for the documents that this "app" deals with
  says that there will be no occurrences of

    "some key": null

  Rather, when the value of "some key" is unknown, this will be expressed by
  the absence of that key.

  The function:

    no_null_keys(jsonb_nn)

  checks that this is honored.
__________________________________________________________________________________________
*/;
\t on

drop function  if exists  no_null_keys   (jsonb_nn)  cascade;

create function no_null_keys(j in jsonb_nn)
  returns boolean_nn
  immutable
  language sql
as $body$
  select (j = jsonb_strip_nulls(j))::boolean_nn;
$body$;

--------------------------------------------------------------------------------
-- Test it.

drop function if exists j()                  cascade;
drop function if exists no_null_keys_test()  cascade;
drop type     if exists t1                   cascade;
drop type     if exists t2                   cascade;

create type             t1 as (k int, v text);
create type             t2 as (a int, b int, c t1, d t1, e text[]);

create function j()
  returns jsonb
  language plpgsql
as $body$
declare
  t    constant text    not null := 'How we wrote a regular expression to detect occurrences of « "some key": null » in our JSON documents!';
  c1   constant t1      not null := (17, t);
  c2   constant t1      not null := (29, null);
  arr  constant text[]  not null := array['x', null::text, t];
  r    constant t2      not null := (42, null, c1, c2, arr);
begin
  return to_jsonb(r);
end;
$body$;
select jsonb_pretty(j());
select jsonb_pretty(jsonb_strip_nulls(j()));

create function no_null_keys_test()
  returns text
  language plpgsql
as $body$
declare
  b1 constant boolean_nn := no_null_keys(                   j() );
  b2 constant boolean_nn := no_null_keys(jsonb_strip_nulls( j() ));
begin
  return
    'no_null_keys(raw input): '     ||b1::text||'   |   '||
    'no_null_keys(stripped input): '||b2::text;
end;
$body$;
select no_null_keys_test();

drop function if exists j()                  cascade;
drop function if exists no_null_keys_test()  cascade;
drop type     if exists t1                   cascade;
drop type     if exists t2                   cascade;

\t off
