/*
  BEWARE!
  -------
  https://www.postgresql.org/docs/11/sql-createtable.html

  The ON DELETE clause specifies the action to perform when a referenced row
  in the "masters" table is deleted... Referential actions other than the
  NO ACTION check cannot be deferred, even if the constraint is declared deferrable...

  RESTRICT
  Produce an error... the deletion or update would create a FK constraint violation.
  This is the same as NO ACTION except that the check is not deferrable.

  Because, for each table, the FK constraint is on a single column
  and this column has a NOT NULL constraint, the MATCH clause has
  no consequence and is therefore omitted.

  INITIALLY DEFFERED impies DEFERRABLE and so is omitted.
*/;
------------------------------------------------------------------------------------------

set role d4$data;
grant usage on schema data to d4$code;

create table data.masters(
  mk  serial constraint masters_pk primary key,

      -- Unique. Here's where the "one" in "one-to-many" comes from.
  dk  int not null unique,

  v   text not null unique);

revoke all    on table    data.masters        from public;
grant  select on table    data.masters        to   d4$code;
grant  insert on table    data.masters        to   d4$code;
grant  update on table    data.masters        to   d4$code;
grant  delete on table    data.masters        to   d4$code;

revoke all    on sequence data.masters_mk_seq from public;
grant  usage  on sequence data.masters_mk_seq to   d4$code;

create table data.details(
  dk  serial constraint details_pk primary key,

      -- Not unique. Here's where the "many" in "one-to-many" comes from.
  mk  int not null,

  v   text not null unique);

-- Written as a separate "alter" simply to emphasise the symmetry between
-- the two tables.
alter table data.details add
  constraint masters_fk foreign key(mk) references data.masters(mk)

  -- Allow deleting a "masters" row with all of its details.
  on delete cascade

  initially deferred;

-- Must be written as a separate "alter" (of course).
alter table data.masters add
  constraint details_fk foreign key(dk) references data.details(dk)
  initially deferred;

revoke all    on table    data.details        from public;
grant  select on table    data.details        to   d4$code;
grant  insert on table    data.details        to   d4$code;
grant  update on table    data.details        to   d4$code;
grant  delete on table    data.details        to   d4$code;

revoke all    on sequence data.details_dk_seq from public;
grant  usage  on sequence data.details_dk_seq to   d4$code;
