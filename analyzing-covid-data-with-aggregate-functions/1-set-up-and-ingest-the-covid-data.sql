\c d1 d1$mgr
call mgr.cr_role('covid', comment=>'Owns all the objects for the "Analyzing COVID data with aggregate functions" case study.');
call mgr.prepend_to_current_search_path('covid');
call mgr.set_role('covid');

------------------------------------------------------------------------------------------------------------------------
-- Set up the infrastructure and create the tables.

drop table if exists covidcast_names cascade;
create table covidcast_names(csv_file text primary key, staging_table text not null, signal text not null);

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

-- Each of these files contains 50 days of observations.
do $body$
declare
  -- Here is the symbolic link in use.
  dir constant text not null := '/etc/ysql-case-studies/analyzing-covid-data-with-aggregate-functions/20-input-csv-files/';
begin
  insert into covidcast_names(csv_file, staging_table, signal) values
    (dir||'covidcast-fb-survey-smoothed_'|| 'wearing_mask' ||'-2020-09-13-to-2020-11-01.csv', 'mask_wearers',   'smoothed_wearing_mask'),
    (dir||'covidcast-fb-survey-smoothed_'|| 'cli'          ||'-2020-09-13-to-2020-11-01.csv', 'symptoms',       'smoothed_cli'),
    (dir||'covidcast-fb-survey-smoothed_'|| 'hh_cmnty_cli' ||'-2020-09-13-to-2020-11-01.csv', 'cmnty_symptoms', 'smoothed_hh_cmnty_cli');
  end;
$body$;

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
