-- DEMONSTRATE GOOD DATA MODELING PRACTICE

create function employees.name_ok(i in text)
  returns boolean
  set search_path = pg_catalog, pg_temp
  language sql
as $body$
  select
    case
      when (lower(i) = i and length(i) <=30) or i is null  then true
      else                                                      false
    end;
$body$;

create domain employees.name_t as text check(employees.name_ok(value));

create table employees.emps(
  name     employees.name_t primary key,
  mgr_name employees.name_t);

-- The order of insertion is arbitrary
insert into employees.emps(name, mgr_name) values
  ('mary',   null  ),
  ('fred',   'mary'),
  ('susan',  'mary'),
  ('john',   'mary'),
  ('doris',  'fred'),
  ('alice',  'john'),
  ('bill',   'john'),
  ('joan',   'bill'),
  ('george', 'mary'),
  ('edgar',  'john'),
  ('alfie',  'fred'),
  ('dick',   'fred');

-- The ultimate manager has no manager.
-- Enforce the business rule "Maximum one ultimate manager".
-- Expression-based index.
create unique index t_mgr_name on employees.emps((mgr_name is null)) where mgr_name is null;

-- Implement the one-to-many "pig's ear".
alter table employees.emps
add constraint emps_mgr_name_fk
foreign key(mgr_name) references employees.emps(name)
on delete restrict;

-- Order by... nulls first
select name, mgr_name
from employees.emps
order by mgr_name nulls first, name;

-- Try these by hand to see the errors.
/*
  insert into employees.emps(name, mgr_name) values ('second boss', null);
  insert into employees.emps(name, mgr_name) values ('emily', 'steve');
  insert into employees.emps(name, mgr_name) values ('Emily', 'dick');
*/;
