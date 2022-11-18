\t on
select rule_off('02-cr-detect-and-strip-null-keys', 'level_3');
\t off

/*
——————————————————————————————————————————————————————————————————————————————————————————

  The informally expressed JSON Schema for the documents that this "app" deals with
  says that there will be no occurrences of

    "some key": null

  Rather, when the value of "some key" is unknown, this will be expressed by
  the absence of that key.

  The function:

    no_null_keys(jsonb)

  checks that this is honored.
__________________________________________________________________________________________
*/;
\t on

create function no_null_keys(j in jsonb)
  returns boolean
  immutable
  language sql
as $body$
  select (j = jsonb_strip_nulls(j))::boolean;
$body$;

--------------------------------------------------------------------------------
-- Test it. Use temporary types t1 and t2 and temporary function j().
-- They are not needed once the test is done.

create type pg_temp.t1 as (k int, v text);
create type pg_temp.t2 as (a int, b int, c pg_temp.t1, d pg_temp.t1, e text[]);

create function pg_temp.j()
  returns jsonb
  language plpgsql
as $body$
declare
  t    constant text    not null := 'How we wrote a regular expression to detect occurrences '||
                                    'of « "some key": null » in our JSON documents!';
  c1   constant pg_temp.t1  not null := (17, t);
  c2   constant pg_temp.t1  not null := (29, null);
  arr  constant text[]      not null := array['x', null::text, t];
  r    constant pg_temp.t2  not null := (42, null, c1, c2, arr);
begin
  return to_jsonb(r);
end;
$body$;

select jsonb_pretty(pg_temp.j());
select jsonb_pretty(jsonb_strip_nulls(pg_temp.j()));

create function no_null_keys_test()
  returns text
  language plpgsql
as $body$
declare
  b1 constant boolean not null := no_null_keys(                   pg_temp.j() );
  b2 constant boolean not null := no_null_keys(jsonb_strip_nulls( pg_temp.j() ));
begin
  return
    'no_null_keys(raw input): '     ||b1::text||'   |   '||
    'no_null_keys(stripped input): '||b2::text;
end;
$body$;

select no_null_keys_test();

\t off
