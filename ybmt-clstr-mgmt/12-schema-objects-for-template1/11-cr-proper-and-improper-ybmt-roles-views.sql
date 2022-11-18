/*
  An "improper role" is not "proper" according to the rules defined by
  the "YBMT" multitenancy scheme.

  A proper "YBMT" role is defined thus:

    EITHER It's listed by the "mgr.reserved_roles" view

    OR     It's listed by the "mgr.tenant_roles" view for one particular database AND
           has is_good_tenant_role_name() TRUE
*/;
--------------------------------------------------------------------------------

create view mgr.proper_ybmt_roles(name) as
with
  non_reserved_role_with_connectable_db_pairs(r_name, d_name) as (
      select
        r.name, d.datname
      from
        mgr.non_reserved_roles r
        cross join
        pg_database d
      where has_database_privilege(r.name, d.datname, 'connect')),

  non_reserved_role_with_connectable_dbs_pairs(r_name, dbs) as (
    select r_name, array_agg(d_name)
    from non_reserved_role_with_connectable_db_pairs
    group by r_name),

  properly_named_tenant_roles(name) as(
    select r_name
    from non_reserved_role_with_connectable_dbs_pairs
    where mgr.is_good_tenant_role_name(r_name)
    and cardinality(dbs) = 1)

select name from properly_named_tenant_roles
union all
select name from mgr.reserved_roles;

revoke all    on table mgr.proper_ybmt_roles from public; 
grant  select on table mgr.proper_ybmt_roles to   clstr$developer;
--------------------------------------------------------------------------------

create view mgr.improper_ybmt_roles(name) as
select rolname
from pg_roles r
where not exists
  (
    select 1 from mgr.proper_ybmt_roles a
    where a.name = r.rolname
  );

revoke all    on table mgr.improper_ybmt_roles from public; 
grant  select on table mgr.improper_ybmt_roles to   clstr$developer;
--------------------------------------------------------------------------------

drop function if exists mgr.improper_ybmt_roles() cascade;

create function mgr.improper_ybmt_roles()
  returns table(z text)
  stable
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  roles constant text[] := (
    select array_agg(name::text order by name) from mgr.improper_ybmt_roles);
begin
  if roles is not null and cardinality(roles) > 0 then
    z := 'surviving improper role';                                 return next;
    z := '-----------------------';                                 return next;
    foreach z in array roles loop
      /* */                                                         return next;
    end loop;
  end if;
end;
$body$;

revoke all     on function mgr.improper_ybmt_roles() from public;
grant  execute on function mgr.improper_ybmt_roles() to   clstr$developer;
