\t on
select caption('03-typecasting-text-to-json(b)-to-text');
--------------------------------------------------------------------------------

drop function if exists "text to json(b) to text results"() cascade;
create function "text to json(b) to text results"()
  returns table(z text)
  language plpgsql
as $body$
declare
  t constant text not null := '
      [
        {"aa": 11, "bb": 12, "aaa": 13, "bbb": 14, "c": 15},
        {"c": 25, "bbb": 24, "aaa": 23, "bb": 22, "aa": 21}
      ]
  ';

  unparsed    constant json  not null := t::json;
  t_unparsed  constant text  not null := unparsed::text;

  parsed      constant jsonb not null := t::jsonb;
  t_parsed    constant text  not null := parsed::text;
  pretty      constant text  not null := jsonb_pretty(parsed);
begin
  assert t_unparsed = t;

  z := t_parsed;                                         return next;
  z := '';                                               return next;
  z := pretty;                                           return next;
end;
$body$;

select z from "text to json(b) to text results"();

with c(v) as(
  values ('c'), ('bbb'), ('aaa'), ('bb'), ('aa')
  )
select v from c order by v;
\t off
