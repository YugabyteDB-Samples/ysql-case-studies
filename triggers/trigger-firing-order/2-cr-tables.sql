create table trg_firing_order.masters(
  mk  serial primary key,
  v   text not null unique);

create table trg_firing_order.details(
  mk  int,
  dk  serial,
  v   text not null unique,

  constraint details_pk primary key(mk, dk),

  constraint details_fk foreign key(mk)
    references trg_firing_order.masters(mk)
    on delete cascade);
