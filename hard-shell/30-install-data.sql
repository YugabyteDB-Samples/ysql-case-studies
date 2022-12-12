set role d3$data;

grant usage on schema data to d3$code;

-- For unit testing code and ad hoc demo code.
grant usage on schema data to d3$qa;
--------------------------------------------------------------------------------

create table data.masters(
  mk uuid
    default extensions.gen_random_uuid()
    constraint masters_pk primary key,
  v text
    not null
    constraint masters_v_unq unique
    constraint masters_v_chk check(length(v) between 3 and 10));

revoke all                           on table data.masters from public;
grant select, insert, update, delete on table data.masters to   d3$code;
grant select, insert, update, delete on table data.masters to   d3$qa;
------------------------------------------------------------

create table data.details(
  mk uuid,
  dk
    uuid default extensions.gen_random_uuid(),
  v text
    not null
    constraint details_v_chk check(length(v) between 3 and 20),

  constraint details_pk primary key(mk, dk),

  constraint details_fk foreign key(mk)
    references data.masters(mk)
    on delete cascade,

  constraint details_mk_v_unq unique(mk, v));

revoke all                           on table data.details from public;
grant select, insert, update, delete on table data.details to   d3$code;
grant select, insert, update, delete on table data.details to   d3$qa;
