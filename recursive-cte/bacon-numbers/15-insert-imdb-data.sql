/*
  Define "YSQL_CASE_STUDIES" to denote the full path for the top directory "ysql-case-studies"
  wherever you place the locally cloned repo on your machine.

  This is an ugly but apparently necessary workaround.
  The "\copy" metacommand has no syntax ("like "\copyr" is to "\copy" as "\ir" is to "\i") to
  expresss that the path "imdb-data/imdb.small.txt" is to be treated as relative to the directory
  where the script in which it is invoked is found. Rather, it's taken as relative to the
  current working directory from which "psql" or "ysqlsh" is invoked.

  Nor does the "\copy" metacommand understand an environment variable. 

  So the only way to make the present script work when current working directory from which
  "psql" or "ysqlsh" is invoked is not fixed is to use an absolute path.

  The source file for \"copy" is first copied to "/tmp/" so that the "\copy" command itself
  will be easier too read.

  Fortunately, the "\!" metacomand, because it simply passes its patload to the O/S, IS able to
  an environment variable.
*/;
\! cp $YSQL_CASE_STUDIES/recursive-cte/bacon-numbers/imdb-data/imdb.small.txt /tmp/imdb.small.txt

delete from edges;
delete from cast_members;
delete from actors;
delete from movies;

alter table cast_members drop constraint cast_members_fk1;
alter table cast_members drop constraint cast_members_fk2;

\copy cast_members(actor, movie) from '/tmp/imdb.small.txt' with delimiter '|';

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
