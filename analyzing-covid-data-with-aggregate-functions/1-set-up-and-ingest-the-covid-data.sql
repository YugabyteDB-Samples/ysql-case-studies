\c d1 d1$mgr
call mgr.cr_role('covid', comment=>'Owns all the objects for the "Analyzing COVID data with aggregate functions" case study.');
call mgr.prepend_to_session_path('covid');
set role d1$covid;

------------------------------------------------------------------------------------------------------------------------
-- Set up the infrastructure and create the tables.

drop table if exists covidcast_names cascade;
create table covidcast_names(csv_file text primary key, staging_table text not null, signal text not null);

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
\! cp $YSQL_CASE_STUDIES/analyzing-covid-data-with-aggregate-functions/20-input-csv-files/*.csv /tmp/

-- Each of these files contains 50 days of observations.
insert into covidcast_names(csv_file, staging_table, signal) values
  ('/tmp/covidcast-fb-survey-smoothed_'|| 'wearing_mask' ||'-2020-09-13-to-2020-11-01.csv', 'mask_wearers',   'smoothed_wearing_mask'),
  ('/tmp/covidcast-fb-survey-smoothed_'|| 'cli'          ||'-2020-09-13-to-2020-11-01.csv', 'symptoms',       'smoothed_cli'),
  ('/tmp/covidcast-fb-survey-smoothed_'|| 'hh_cmnty_cli' ||'-2020-09-13-to-2020-11-01.csv', 'cmnty_symptoms', 'smoothed_hh_cmnty_cli');

create unique index covidcast_names_staging_table_unq on covidcast_names(staging_table);
create unique index covidcast_names_signal_unq on covidcast_names(signal);

\ir 10-ingest-the-covid-data-helpers/1-cr-cr-staging-tables.sql
\ir 10-ingest-the-covid-data-helpers/2-cr-cr-copy-from-csv-scripts.sql

call cr_staging_tables();

--------------------------------------------------------------------------------
-- Import the CSV files into the staging tables;
\t on

\o /tmp/copy_from_csv.sql
select cr_copy_from_scripts(1);
\o
\i /tmp/copy_from_csv.sql

\o /tmp/copy_from_csv.sql
select cr_copy_from_scripts(2);
\o
\i /tmp/copy_from_csv.sql

\o /tmp/copy_from_csv.sql
select cr_copy_from_scripts(3);
\o
\i /tmp/copy_from_csv.sql

\t off

--------------------------------------------------------------------------------
-- Check that the imported data is consistent with what was assumed about its
-- format and content. If the checks pass, then merge it into the single
-- "covidcast_fb_survey_results" table.

\ir 10-ingest-the-covid-data-helpers/3-cr-assert-assumptions-ok.sql
\ir 10-ingest-the-covid-data-helpers/4-cr-xform-to-covidcast-fb-survey-results.sql

do $body$
begin
  -- If "assert_assumptions_ok()" aborts with an assert failure,
  -- then "cr_covidcast_fb_survey_results()" will not be called.
  call assert_assumptions_ok(
    start_survey_date => to_date('2020-09-13', 'yyyy-mm-dd'),
    end_survey_date   => to_date('2020-11-01', 'yyyy-mm-dd'));
  call xform_to_covidcast_fb_survey_results();
end;
$body$;
