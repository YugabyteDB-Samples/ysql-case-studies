\t on
select caption('02-examples-of-json-values-and-value-extraction');
--------------------------------------------------------------------------------

drop function if exists jsonb_values() cascade;
create function jsonb_values()
  returns table(z jsonb)
  language plpgsql
as $body$
declare
  j constant jsonb not null := '[
                                  {"k1": "a", "k2": [17, 42]},
                                  {"k3": {"k4": 5, "k6": null}}
                                ]';
begin
  z := '     "v"                                                              '; return next;
  z := '     42                                                               '; return next;
  z := '     true                                                             '; return next;
  z := '     null                                                             '; return next;
  z := '     {}                                                               '; return next;
  z := '     []                                                               '; return next;
  z := '     {"k": "v"}                                                       '; return next;
  z := '     {"k": 42}                                                        '; return next;
  z := '     {"k": true}                                                      '; return next;
  z := '     {"k": null}                                                      '; return next;
  z := '     ["v", 42, true, null]                                            '; return next;
  z := '     {"k1": 1, "k2": {"k3": "v", "k4": ["v", 42]}}                    '; return next;
  z := '     [{"k1": "a", "k2": [17, 42]}, {"k3": {"k4": 5, "k6": null}}]     '; return next;

  z :=       j->0                                                              ; return next;
  z :=       (j->0)->'k2'                                                      ; return next;
  z :=       ((j->0)->'k2')->1                                                 ; return next;
end;
$body$;

select z::text from jsonb_values();
\t off
