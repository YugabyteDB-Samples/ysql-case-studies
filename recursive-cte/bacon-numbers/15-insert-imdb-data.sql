/*
  Define the symbolic link "/etc/ysql-case-studies" to denote the full path for the top directory
  "ysql-case-studies" wherever you place the locally cloned repo on your machine.

  Alternatively, simply place the "ysql-case-studies" to keep path spellings relatively short
  and replace the leading "/etc/" used here with whatever you choose.

  WHY?

  The "\copy" meta-command has no syntax ("like "\copyr" is to "\copy" as "\ir" is to "\i") to
  express that a relative path is to be treated as relative to the directory where the script
  in which it is invoked is found. Rather, it's taken as relative to the current working directory
  from which "psql" or "ysqlsh" is invoked. Nor does "\copy" understand an environment variable.

  If you want to be able to use scripts like this one when "psql" or "ysqlsh" is invoked from
  two or more different directories, you therefore have to use an absolute path. Because this might
  be quite long, you can use a symbolic link (which "\copy" does understand).
*/;

delete from edges;
delete from cast_members;
delete from actors;
delete from movies;

alter table cast_members drop constraint cast_members_fk1;
alter table cast_members drop constraint cast_members_fk2;

\copy cast_members(actor, movie) from '/etc/ysql-case-studies/recursive-cte/bacon-numbers/imdb-data/imdb.small.txt' with delimiter '|';

insert into actors select distinct actor from cast_members;
insert into movies select distinct movie from cast_members;

alter table cast_members
add constraint cast_members_fk1 foreign key (actor)
  references actors(actor)
  match full
  on delete cascade
  on update restrict;

alter table cast_members
add constraint cast_members_fk2 foreign key(movie)
  references movies(movie)
  match full
  on delete cascade
  on update restrict;

\t on
select 'count(*) from cast_members... '||to_char(count(*), '9,999') from cast_members;
select 'count(*) from actors......... '||to_char(count(*), '9,999') from actors;
select 'count(*) from movies......... '||to_char(count(*), '9,999') from movies;
\t off
