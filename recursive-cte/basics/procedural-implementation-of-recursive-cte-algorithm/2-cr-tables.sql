create table final_results(
  c1 int not null,
  c2 int not null,
  constraint final_results_pk primary key(c1, c2));

create table previous_results(
  c1 int not null,
  c2 int not null,
  constraint previous_results_pk primary key(c1, c2));

create table temp_results(
  c1 int not null,
  c2 int not null,
  constraint temp_results_pk primary key(c1, c2));
