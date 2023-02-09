create view covid.covidcast_fb_survey_results_v as
select
  survey_date,
  state,
  mask_wearing_pct,
  cmnty_symptoms_pct as symptoms_pct
from covid.covidcast_fb_survey_results;

\t on
select client_safe.rule_off('Basic COVID data analysis.', 'level_2');
select client_safe.rule_off('Symptoms by state for survey date = 2020-10-21.', 'level_3');
\t off
select
  round(mask_wearing_pct)  as "% wearing mask",
  round(symptoms_pct)      as "% with symptoms",
  state
from covid.covidcast_fb_survey_results_v
where survey_date = to_date('2020-10-21', 'yyyy-mm-dd')
order by 1, 2, 3;

\t on
select client_safe.rule_off('Symptoms by state, overall average.', 'level_3');
\t off
select
  round(avg(mask_wearing_pct))  as "% wearing mask",
  round(avg(symptoms_pct))      as "% with symptoms",
  state
from covid.covidcast_fb_survey_results_v
group by state
order by 1, 2, 3;

\t on
select client_safe.rule_off('Daily regression analysis report.', 'level_3');
\t off
with a as (
  select
                                                      survey_date,
    avg           (mask_wearing_pct)               as mask_wearing_pct,
    avg           (symptoms_pct)                   as symptoms_pct,
    regr_r2       (symptoms_pct, mask_wearing_pct) as r2,
    regr_slope    (symptoms_pct, mask_wearing_pct) as s,
    regr_intercept(symptoms_pct, mask_wearing_pct) as i
  from covid.covidcast_fb_survey_results_v
  group by survey_date)
select
  to_char(survey_date,      'mm/dd')  as survey_date,
  to_char(mask_wearing_pct,    '90')  as mask_wearing_pct,
  to_char(symptoms_pct,  '90')        as symptoms_pct,
  to_char(r2,  '0.99')                as r2,
  to_char(s,  '90.9')                 as s,
  to_char(i,  '990.9')                as i
from a
order by survey_date;

\t on
select client_safe.rule_off('Regression analysis report for survey date = 2020-10-21.', 'level_3');
\t off
with a as (
  select
    max(survey_date)                               as survey_date,
    regr_slope    (symptoms_pct, mask_wearing_pct) as s,
    regr_intercept(symptoms_pct, mask_wearing_pct) as i
  from covid.covidcast_fb_survey_results_v
  where survey_date = to_date('2020-10-21', 'yyyy-mm-dd'))
select
  to_char(survey_date,      'mm/dd')  as survey_date,
  to_char(s,  '90.9')                 as s,
  to_char(i,  '990.9')                as i
from a;

with a as (
  select regr_r2 (symptoms_pct, mask_wearing_pct) as r2,
  regr_slope    (symptoms_pct, mask_wearing_pct) as s,
  regr_intercept(symptoms_pct, mask_wearing_pct) as i
  from covid.covidcast_fb_survey_results_v
  group by survey_date)
select
  to_char(avg(r2), '0.99') as "avg(R-squared)",
  to_char(avg(s), '0.99') as "avg(s)",
  to_char(avg(i), '990.99') as "avg(i)"
from a;

\t on
select client_safe.rule_off(array[
  'COVID data analysis results for graphing.',
  'Copy these results to a ".csv" file for graphing']);
select
  round(mask_wearing_pct)::text||','||round(symptoms_pct)::text
from covid.covidcast_fb_survey_results_v
where survey_date = to_date('2020-10-21', 'yyyy-mm-dd')
order by 1;
\t off
