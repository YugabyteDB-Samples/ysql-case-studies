create table cte_basics_proc.final_results(
  c1 int not null,
  c2 int not null,
  constraint final_results_pk primary key(c1, c2));

create table cte_basics_proc.previous_results(
  c1 int not null,
  c2 int not null,
  constraint previous_results_pk primary key(c1, c2));

create table cte_basics_proc.temp_results(
  c1 int not null,
  c2 int not null,
  constraint temp_results_pk primary key(c1, c2));
