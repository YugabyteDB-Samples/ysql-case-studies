create table actors(actor text primary key);

create table movies(movie text primary key);

create table cast_members(
  actor text not null,
  movie text not null,

  constraint cast_members_pk primary key(actor, movie),

  constraint cast_members_fk1 foreign key(actor)
    references actors(actor)
    match full
    on delete cascade
    on update restrict,

  constraint cast_members_fk2 foreign key(movie)
    references movies(movie)
    match full
    on delete cascade
    on update restrict
  );
