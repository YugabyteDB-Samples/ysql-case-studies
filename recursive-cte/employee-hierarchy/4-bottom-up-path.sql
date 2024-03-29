-- Use a prepared statement parameterized by employee of interest.
-- Notice that the result of "prepare" is not a schema-object and so
-- the attempt to shema-qualify its name causes an error.
prepare bottom_up_simple(text) as
with
  recursive hierarchy_of_emps(depth, name, mgr_name) as (

    -- Non-recursive term.
    -- Select the exactly one employee of interest.
    -- Define the depth to be zero.
    (
      select
        0,
        name,
        mgr_name
      from employees.emps             
      where name = $1
    )

    union all

    -- Recursive term.
    -- Treat the employee from the previous iteration as a report.
    -- Join this with its manager.
    -- Increase the depth with each step upwards.
    -- Stop when the current putative report has no manager, i.e. is
    -- the ultimate manager.
    -- Each successive iteration goes one level higher in the hierarchy.
    (
      select
        h.depth + 1,
        e.name,
        e.mgr_name
      from
      employees.emps as e
      inner join
      hierarchy_of_emps as h on h.mgr_name = e.name
    )
  )
select
  depth,
  name,
  coalesce(mgr_name, null, '-') as mgr_name
from hierarchy_of_emps;

execute bottom_up_simple('joan');

create function employees.bottom_up_path(start_name in text)
  returns employees.name_t[]
  set search_path = pg_catalog, employees, pg_temp
  language sql
as $body$
  with
    recursive hierarchy_of_emps(mgr_name, path) as (
      (
        select mgr_name, array[name]
        from emps             
        where name = start_name
      )
      union all
      (
        select e.mgr_name, h.path||e.name
        from
        emps as e
        inner join
        hierarchy_of_emps as h on e.name = h.mgr_name
      )
    )
  select path
  from hierarchy_of_emps
  order by cardinality(path) desc
  limit 1;
$body$;

select employees.bottom_up_path('joan');

create function employees.bottom_up_path_display(start_name in text)
  returns text
  set search_path = pg_catalog, employees, pg_temp
  language plpgsql
as $body$
declare
  path constant name_t[] not null := (bottom_up_path(start_name));
  t text not null := path[1]::text;
begin
  for j in 2..cardinality(path) loop
    t := t||' > '||path[j];
  end loop;
  return t;
end;
$body$;

\t on
select employees.bottom_up_path_display('joan');
select employees.bottom_up_path_display('doris');
\t off
