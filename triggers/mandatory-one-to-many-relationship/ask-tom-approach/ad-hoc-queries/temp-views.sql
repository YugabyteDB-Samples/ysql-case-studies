\c d4 d4$mgr
call mgr.set_role('data');

create temporary view masters_left_outer_join_details("m.mk", "m.dk", "d.dk", "m.v", "d.v") as
select                                                 m.mk,   m.dk,   d.dk,   m.v,   d.v
from
  data.masters m
  left outer join
  data.details d
  using (mk);

create temporary view masters_full_outer_join_details("m.mk", "m.dk", "d.dk", "m.v", "d.v") as
select                                                 m.mk,   m.dk,   d.dk,   m.v,   d.v
from
  data.masters m
  full outer join
  data.details d
  using (mk);

select * from pg_temp.masters_left_outer_join_details order by 4, 5;

select * from pg_temp.masters_full_outer_join_details order by 4, 5;
