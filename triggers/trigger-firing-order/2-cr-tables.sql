create table masters(
  mk  serial primary key,
  v   text not null unique);

create table details(
  mk  int,
  dk  serial,
  v   text not null unique,

  constraint details_pk primary key(mk, dk),

  constraint details_fk foreign key(mk)
    references masters(mk)
    on delete cascade);
