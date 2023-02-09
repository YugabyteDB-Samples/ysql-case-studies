create view trg_firing_order.internal_triggers(tab_name, name, def) as
select
  c.relname,
  t.tgname,
  pg_get_triggerdef(t.oid, true)
from
  pg_trigger t
  inner join
  pg_class c
  on c.oid = t.tgrelid
  inner join
  pg_roles r
  on c.relowner = r.oid
where r.rolname like '%trg_firing_order'
and   t.tgisinternal;

\x on
select name, tab_name, rpad(def, 58)||'...' as def from trg_firing_order.internal_triggers limit 1;

with c(name, def) as (
  select name, replace(def,
    'NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION', 'execute')
  from trg_firing_order.internal_triggers)
select replace(def,
  'CREATE CONSTRAINT TRIGGER '||quote_ident(name), '') as definition
from c
order by 1;
\x off
