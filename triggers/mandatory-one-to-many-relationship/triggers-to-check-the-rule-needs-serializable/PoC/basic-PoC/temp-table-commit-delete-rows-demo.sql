:u1
:c

-- The "unlogged" option can't be used for a temp table.
-- It's implicit inb the concept.
create temp table cascade_delete_flag(
  val boolean not null)
  on commit delete rows;

start transaction;
insert into cascade_delete_flag(val) values(true);
select exists (select 1 from cascade_delete_flag)::text;
commit;

select exists (select 1 from cascade_delete_flag)::text;
