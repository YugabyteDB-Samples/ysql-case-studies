create table bacon.actors(actor text primary key);

create table bacon.movies(movie text primary key);

create table bacon.cast_members(
  actor text not null,
  movie text not null,

  constraint cast_members_pk primary key(actor, movie),

  constraint cast_members_fk1 foreign key(actor)
    references bacon.actors(actor)
    match full
    on delete cascade
    on update restrict,

  constraint cast_members_fk2 foreign key(movie)
    references bacon.movies(movie)
    match full
    on delete cascade
    on update restrict
  );
