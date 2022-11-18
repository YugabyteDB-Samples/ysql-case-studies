-- #1: "at_timezone(text, timestamp)" overload.
-- There's no value in including a bad-value negative test because doing so would simply be a repeat,
-- and therefore redundant, test of the assert_approved_timezone_name() procedure.
-- See "do-set-timezone-tests.sql".
do $body$
declare
  t_text       constant text        not null := '2021-05-31 12:00:00';
  t_plain      constant timestamp   not null := t_text;
  tz_result             timestamptz not null := t_text||' UTC'; -- Satisfy the constraints.
  tz_expected           timestamptz not null := t_text||' UTC'; -- The values will be overwritten
  tz                    text        not null := '';

  good_zones constant text[] := array[
    'UTC',
    'Asia/Kathmandu',
    'Europe/Amsterdam'];
begin
  foreach tz in array good_zones loop
    tz_result   := at_timezone(tz, t_plain);
    tz_expected := t_text||' '||tz;

    declare
      msg constant text not null := tz||' assert failed';
    begin
      assert tz_result = tz_expected, msg; 
    end;
  end loop;
end;
$body$;

-- #2: "at_timezone(interval, timestamp)" overload.
do $body$
declare
  t_text       constant text        not null := '2021-05-31 12:00:00';
  t_plain      constant timestamp   not null := t_text;
  tz_result             timestamptz not null := t_text||' UTC'; -- Satisfy the constraints.
  tz_expected           timestamptz not null := t_text||' UTC'; -- The values will be overwritten
  i                     interval    not null := make_interval();
  hh                    text        not null := 0;
  mm                    text        not null := 0;

  i_vals       constant interval[]  not null := array[
                                                    make_interval(),
                                                    make_interval(hours=>4, mins=>30),
                                                    make_interval(hours=>-7)
                                                  ];
begin
  foreach i in array i_vals loop
    hh := ltrim(to_char(extract(hour   from i), 'SG09')); -- Essential to prefix with the sign.
    mm := ltrim(to_char(extract(minute from i), '09'));
    tz_result   := at_timezone(i, t_plain);
    tz_expected := t_text||' '||hh||':'||mm;
    declare
      msg constant text not null := i::text||' assert failed';
    begin
      assert tz_result = tz_expected, msg; 
    end;
  end loop;
end;
$body$;
