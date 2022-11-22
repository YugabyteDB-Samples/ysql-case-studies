set role d5$data;
grant usage on schema data to d5$code;

create table data.masters(
  mk uuid default extensions.gen_random_uuid()
    constraint masters_pk primary key,

  v text not null
    constraint masters_v_unq unique
);

revoke all    on table data.masters from public;
grant  select on table data.masters to   d5$code;
grant  insert on table data.masters to   d5$code;
grant  delete on table data.masters to   d5$code;

create table data.details(
  mk uuid,
  dk uuid default extensions.gen_random_uuid(),
  v  text not null,

  constraint details_pk primary key(mk, dk),

  constraint details_fk foreign key(mk)
    references data.masters(mk)
    on delete cascade
    initially deferred,

  constraint details_mk_v_unq unique(mk, v)
);

revoke all    on table data.details from public;
grant  select on table data.details to   d5$code;
grant  insert on table data.details to   d5$code;
grant  delete on table data.details to   d5$code;
