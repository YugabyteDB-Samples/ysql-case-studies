create procedure covid.assert_assumptions_ok(start_survey_date in date, end_survey_date in date)
  set search_path = pg_catalog, covid, pg_temp
  language plpgsql
as $body$
declare
  -- Each survey date (i.e. "time_value") has exactly the same number of states (i.e. "geo_value").
  -- Each state has the same number, of survey date values.

  expected_states constant text[] not null := array[
    'ak', 'al', 'ar', 'az', 'ca', 'co', 'ct', 'dc', 'de', 'fl', 'ga',
    'hi', 'ia', 'id', 'il', 'in', 'ks', 'ky', 'la', 'ma', 'md',
    'me', 'mi', 'mn', 'mo', 'ms', 'mt', 'nc', 'nd', 'ne', 'nh',
    'nj', 'nm', 'nv', 'ny', 'oh', 'ok', 'or', 'pa', 'ri', 'sc',
    'sd', 'tn', 'tx', 'ut', 'va', 'vt', 'wa', 'wi', 'wv', 'wy'
  ];

  expected_state_count constant int := cardinality(expected_states);

  signal_qry constant text not null :=
    'select distinct signal from covid.%I';

  actual_states_qry constant text not null :=
    'select array_agg(distinct geo_value order by geo_value) from %I';

  actual_states text[] not null := '{}';

  expected_dates date[] not null := array[start_survey_date];

  actual_dates_qry constant text not null :=
    'select array_agg(distinct time_value order by time_value) from %I';

  actual_dates date[] not null := '{}';

  expected_date_count int not null := 0;

  names constant covid.covidcast_names[] not null := (
    select array_agg((csv_file, staging_table, signal)::covid.covidcast_names) from covid.covidcast_names);

  expected_total_count int not null := 0;

  r covid.covidcast_names not null := ('', '', '');
  d  date     not null := start_survey_date;
  t  text     not null := '';
  n  int      not null := 0;
  b  boolean  not null := false;
begin
  loop
    d := d + interval '1 day';
    expected_dates := expected_dates||d;
    exit when d >= end_survey_date;
  end loop;
  expected_date_count := cardinality(expected_dates);
  expected_total_count := expected_state_count*expected_date_count;

  foreach r in array names loop

    -- signal: One of covid.covidcast_names.signal.
    execute format(signal_qry, r.staging_table) into t;
    assert t = r.signal, 'signal from '||r.staging_table||' <> "'||r.signal||'"';

    -- geo_type: state.
    execute 'select distinct geo_type from '||r.staging_table into t;
    assert t = 'state', 'geo_type from '||r.staging_table||' <> "state"';

    -- data_source: fb-survey.
    execute 'select distinct data_source from '||r.staging_table into t;
    assert t = 'fb-survey', 'data_source from '||r.staging_table||' <> "fb-survey"';

    -- direction: IS NULL.
    execute $$select distinct coalesce(direction, '<null>') from $$||r.staging_table into t;
    assert t = '<null>', 'direction from '||r.staging_table||' <> "<null>"';

    -- Expected total count(*).
    execute 'select count(*) from '||r.staging_table into n;
    assert n = expected_total_count, 'count from '||r.staging_table||' <> expected_total_count';

    -- geo_value: Check list of actual distinct states is as expected.
    execute format(actual_states_qry, r.staging_table) into actual_states;
    assert actual_states = expected_states, 'actual_states <> expected_states';

    -- geo_value: Expected distinct state (i.e. "geo_value") count(*).
    execute 'select count(distinct geo_value) from '||r.staging_table into n;
    assert n = expected_state_count, 'distinct state count per survey date from '||r.staging_table||' <> expected_state_count';

    -- time_value: Check list of actual distinct survey dates is as expected.
    execute format(actual_dates_qry, r.staging_table) into actual_dates;
    assert actual_dates = expected_dates, 'actual_dates <> expected_dates';

    -- time_value: Expected distinct survey date (i.e. "time_value") count(*).
    execute 'select count(distinct time_value) from '||r.staging_table into n;
    assert n = expected_date_count, 'distinct survey date count per state from '||r.staging_table||' <> expected_date_count';

    -- Same number of states (i.e. "geo_value") for each distinct survey date (i.e. "time_value").
    execute '
      with r as (
        select time_value, count(time_value) as n from '||r.staging_table||'
        group by time_value)
      select distinct n from r' into n;
    assert n = expected_state_count, 'distinct state count from '||r.staging_table||' <> expected_state_count';

    -- Same number of survey dates (i.e. "time_value") for each distinct state (i.e. geo_value).
    execute '
      with r as (
        select geo_value, count(geo_value) as n from '||r.staging_table||'
        group by geo_value)
      select distinct n from r' into n;
    assert n = expected_date_count, 'distinct state count from '||r.staging_table||' <> expected_date_count';

    -- value: check is legal percentage value.
    execute '
      select
        max(value) between 0 and 100 and
        min(value) between 0 and 100
      from '||r.staging_table into b;
    assert b, 'max(value), min(value) from '||r.staging_table||' both < 100 FALSE';
  end loop;

  -- code and geo_value: check same exact one-to-one correspondence in all staging tables.
  declare
    chk_code_and_geo_values constant text := $$
    with
      a1 as (
        select to_char(code, '90')||' '||geo_value as v from %I),
      v1 as (
        select v, count(v) as n from a1 group by v),
      a2 as (
        select to_char(code, '90')||' '||geo_value as v from %I),
      v2 as (
        select v, count(v) as n from a2 group by v),
      a3 as (
        select to_char(code, '90')||' '||geo_value as v from %I),
      v3 as (
        select v, count(v) as n from a3 group by v),

      v4 as (select v, n from v1 except select v, n from v2),
      v5 as (select v, n from v2 except select v, n from v1),
      v6 as (select v, n from v1 except select v, n from v3),
      v7 as (select v, n from v3 except select v, n from v1),

      r as (
        select v, n from v4
        union all
        select v, n from v5
        union all
        select v, n from v6
        union all
        select v, n from v6)

    select count(*) from r$$;
  begin
    execute format(chk_code_and_geo_values,
      names[1].staging_table, names[2].staging_table, names[3].staging_table)
      into n;

    assert n = 0, '(code, geo_value) tuples from the three staging tables disagree';
  end;

  -- Check set of (geo_value, time_value) values same in each staging table.
  declare
    chk_putative_pks constant text := '
      with
        v1 as (
          select geo_value, time_value from %1$I
          except
          select geo_value, time_value from %2$I),

        v2 as (
          select geo_value, time_value from %2$I
          except
          select geo_value, time_value from %1$I),

        v3 as (
          select geo_value, time_value from %1$I
          except
          select geo_value, time_value from %3$I),

        v4 as (
          select geo_value, time_value from %3$I
          except
          select geo_value, time_value from %1$I),

        v5 as (
          select geo_value, time_value from v1
          union all
          select geo_value, time_value from v2
          union all
          select geo_value, time_value from v3
          union all
          select geo_value, time_value from v4)

      select count(*) from v5';
  begin
    execute format(chk_putative_pks,
      names[1].staging_table, names[2].staging_table, names[3].staging_table)
      into n;

    assert n = 0, 'pk values from ' ||
      format('%I, %I, %I',
        names[1].staging_table,
        names[2].staging_table,
        names[3].staging_table) ||
        ' do not line up';
  end;
end;
$body$;
