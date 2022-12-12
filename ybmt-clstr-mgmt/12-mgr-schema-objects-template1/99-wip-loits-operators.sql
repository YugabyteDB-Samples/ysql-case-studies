select
  r.rolname as owner,
  n.nspname as schema,
  'operator' as kind,
  o.oprname as name,
  p.proname as implementation
from
  pg_operator o
  inner join
  pg_roles r
  on o.oprowner = r.oid
  inner join
  pg_namespace n
  on o.oprnamespace = n.oid
  inner join
  pg_proc p
  on o.oprcode = p.oid
where n.nspname != 'pg_catalog';
