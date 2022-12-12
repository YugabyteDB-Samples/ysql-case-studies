drop procedure if exists xform_to_covidcast_fb_survey_results() cascade;

create procedure xform_to_covidcast_fb_survey_results()
  language plpgsql
as $body$
declare
  -- Check that the staging tables have the expected names for their roles.
  -- Each subquery assignemnt will fail if doesn't return exactly one row.
  mask_wearers_name    text not null := (select staging_table from covidcast_names where staging_table = 'mask_wearers');
  symptoms_name        text not null := (select staging_table from covidcast_names where staging_table = 'symptoms');
  cmnty_symptoms_name  text not null := (select staging_table from covidcast_names where staging_table = 'cmnty_symptoms');

  stmt text not null := '
    insert into covidcast_fb_survey_results(
      survey_date, state,
      mask_wearing_pct,    mask_wearing_stderr,    mask_wearing_sample_size,
      symptoms_pct,        symptoms_stderr,        symptoms_sample_size,
      cmnty_symptoms_pct,  cmnty_symptoms_stderr,  cmnty_symptoms_sample_size)
    select
      time_value, geo_value,
      m.value, m.stderr, round(m.sample_size),
      s.value, s.stderr, round(s.sample_size),
      c.value, c.stderr, round(c.sample_size)
    from
      %1I as m
      inner join %2I as s using (time_value, geo_value)
      inner join %3I as c using (time_value, geo_value)';

begin
  drop table if exists covidcast_fb_survey_results cascade;

  create table covidcast_fb_survey_results(
    survey_date                 date     not null,
    state                       text     not null,
    mask_wearing_pct            numeric  not null,
    mask_wearing_stderr         numeric  not null,
    mask_wearing_sample_size    int      not null,
    symptoms_pct                numeric  not null,
    symptoms_stderr             numeric  not null,
    symptoms_sample_size        int      not null,
    cmnty_symptoms_pct          numeric  not null,
    cmnty_symptoms_stderr       numeric  not null,
    cmnty_symptoms_sample_size  int      not null,

    constraint covidcast_fb_survey_results_pk primary key (state, survey_date),

    constraint covidcast_fb_survey_results_chk_mask_wearing_pct    check(mask_wearing_pct   between 0 and 100),
    constraint covidcast_fb_survey_results_chk_symptoms_pct        check(symptoms_pct       between 0 and 100),
    constraint covidcast_fb_survey_results_chk_cmnty_symptoms_pct  check(cmnty_symptoms_pct between 0 and 100),

    constraint covidcast_fb_survey_results_chk_mask_wearing_stderr    check(mask_wearing_stderr   > 0),
    constraint covidcast_fb_survey_results_chk_symptoms_stderr        check(symptoms_stderr       > 0),
    constraint covidcast_fb_survey_results_chk_cmnty_symptoms_stderr  check(cmnty_symptoms_stderr > 0),

    constraint covidcast_fb_survey_results_chk_mask_wearing_sample_size    check(mask_wearing_sample_size   > 0),
    constraint covidcast_fb_survey_results_chk_symptoms_sample_size        check(symptoms_sample_size       > 0),
    constraint covidcast_fb_survey_results_chk_cmnty_symptoms_sample_size  check(cmnty_symptoms_sample_size > 0)
  );

  execute format(stmt, mask_wearers_name, symptoms_name, cmnty_symptoms_name);
end;
$body$;
