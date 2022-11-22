create table u1.masters(
  mk  serial primary key,
  v   text not null unique);

create table u1.details(
  mk  int,
  dk  serial,
  v   text not null unique,

  constraint details_pk primary key(mk, dk),

  constraint details_fk foreign key(mk)
    references u1.masters(mk)
    on delete cascade);
