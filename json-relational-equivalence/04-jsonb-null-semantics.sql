\t on
select caption('04-jsonb-null-semantics');
--------------------------------------------------------------------------------

\pset null '<null>'
select
  (null   ::jsonb)::text,
  ('null' ::jsonb)::text;
\pset null ''

select (
    '{"x": 42, "y": null}'::jsonb =
    '{"x": 42           }'::jsonb
  )::text as equal;

drop type if exists r cascade;
create type r as(x int, y int);

drop function if exists jsonb_null_semantics() cascade;
create function jsonb_null_semantics()
  returns table(z text)
  language plpgsql
as $body$
declare
  a1   constant jsonb not null := '{"x": 42, "y": null}';
  a2   constant jsonb not null := '{"x": 42, "y": null}';

  b1   constant jsonb not null := '{"x": 42, "y": null}';
  b2   constant jsonb not null := '{"x": 42           }';

  b1_y constant int            := b1->>'y';
  b2_y constant int            := b2->>'y';

  r1   constant r    not null  := jsonb_populate_record(null::r, b1);
  r2   constant r    not null  := jsonb_populate_record(null::r, b2);

  b3   constant jsonb not null := to_jsonb(r1);
begin
  z := 'a1 = a2:                           '||(a1 = a2)                           ::text; return next;
  z := 'b1 = b2:                           '||(b1 = b2)                           ::text; return next;
  z := '(b1_y is null) and (b2_y is null): '||((b1_y is null) and (b2_y is null)) ::text; return next;
  z := 'r1:                                '||r1                                  ::text; return next;
  z := 'r1 = r2:                           '||(r1 = r2)                           ::text; return next;
  z := 'b3:                                '||b3                                  ::text; return next;
end;
$body$;
select z from jsonb_null_semantics();

\t off
