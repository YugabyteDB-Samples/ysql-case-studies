create procedure do_tests()
  language plpgsql
as $body$
declare
  -- Define all timestamptz values using a zero tz offset.
  -- Fair interpretation of "max legal value is 294276 AD"
  -- and "min legal value is 4713 BC".
  ts_max  constant timestamptz not null := '294276-01-01 00:00:00 UTC AD';
  ts_min  constant timestamptz not null :=   '4713-01-01 00:00:00 UTC BC';

  ts_1    constant timestamptz not null :=   '2021-01-01 00:00:00 UTC AD';
  ts_2    constant timestamptz not null :=   '2000-01-01 00:00:13 UTC AD';
  ts_3    constant timestamptz not null := '294275-06-01 00:00:00 UTC AD';
  ts_4    constant timestamptz not null := '294275-06-01 00:00:13 UTC AD';

  ts_5    constant timestamptz not null := '240271-10-10 07:59:59 UTC AD';
begin
  -- Do all tests using session tz 'UTC'
  set timezone = 'UTC';

  <<"interval_months_t tests">>
  begin
    <<"Test #1">>
    -- Check that given "i = ts_max - ts_min", then "ts_min + i = ts_max".
    declare
      i      constant interval_months_t not null := interval_months(ts_max, ts_min);
      ts_new constant timestamptz       not null := ts_min + i;
    begin
      assert (ts_new = ts_max), 'Test #1 failure';
    end "Test #1";

    <<"Test #2">>
    -- Check that when ts_2 and ts_1 differ in their dd, hh, mi, or ss values,
    -- given "i = ts_1 - ts_2", then "ts_2 + i <> ts_1".
    declare
      i       constant interval_months_t not null := interval_months(ts_1, ts_2);
      ts_new  constant timestamptz       not null := ts_2 + i;
    begin
      assert (ts_new <> ts_1), 'Test #2 failure';
    end "Test #2";
  end "interval_months_t tests";

  <<"interval_days_t tests">>
  begin
    <<"Test #3">>
    -- Check that given "i = ts_max - ts_min", then "ts_min + i = ts_max"
    -- for the full "ts_max, ts_min" range,
    declare
      i      constant interval_days_t not null := interval_days(ts_max, ts_min);
      ts_new constant timestamptz     not null := ts_min + i;
    begin
      assert (ts_new = ts_max), 'Test #3 failure';
    end "Test #3";

    <<"Test #4">>
    -- Check that given "i = ts_3 - ts_min", then "ts_min + i = ts_3"
    -- where ts_3 and ts_min differ by their day number but have their hh:mi:ss the same.
    declare
      i       constant interval_days_t not null := interval_days(ts_3, ts_min);
      ts_new  constant timestamptz     not null := ts_min + i;
    begin
      assert (ts_new = ts_3), 'Test #4 failure';
    end "Test #4";

    <<"Test #5">>
    -- Check that when ts_2 and ts_1 differ in their hh, mi, or ss values,
    -- given "i = ts_4 - ts_min", then "ts_min + i <> ts_4".
    declare
      i       constant interval_days_t not null := interval_days(ts_4, ts_min);
      ts_new  constant timestamptz     not null := ts_min + i;
    begin
      assert (ts_new <> ts_4), 'Test #5 failure';
    end "Test #5";
  end "interval_days_t tests";

  <<"interval_seconds_t tests">>
  begin
    <<"Test #6">>
    -- Check that given "i = ts_5 - ts_min", then "ts_min + i = ts_5"
    -- for the full "ts_5, ts_min" range,
    declare
      i       constant interval_seconds_t not null := interval_seconds(ts_5, ts_min);
      ts_new  constant timestamptz        not null := ts_min + i;
      ts_tol  constant double precision   not null := 0.0005;
    begin
      -- date_trunc('milliseconds', t) is too blunt an instrument.
      assert
        (abs(extract(epoch from ts_new) - extract(epoch from ts_5)) < ts_tol),
        'Test #6 failure';
    end "Test #6";
  end "interval_seconds_t tests";

  <<"Test #7">>
  -- Outcomes from interval multiplication/division.
  declare
    months_result   constant interval_months_t  not null := interval_months (years=>6, months=>1);
    days_result     constant interval_days_t    not null := interval_days   (days=>746);
    seconds_result  constant interval_seconds_t not null := interval_seconds(hours=>359, mins=>20, secs=>25.08);
  begin
    assert (
      -- Notice the use of the "strict equals" operator.
      interval_months(interval_months(years=>3, months=>99), 0.5378) == months_result  and
      interval_days(interval_days(days=>99), 7.5378)                 == days_result    and
      interval_seconds(interval_seconds(hours=>99), 3.6297)          == seconds_result
      ), 'Test #7 failure';
  end "Test #7";

  <<"Test #8">>
  -- Months to days ratio.
  declare
    m      constant interval_months_t not null := interval_months(ts_max, ts_min);
    mm     constant double precision  not null := (interval_mm_dd_ss(m)).mm;
    ym     constant double precision  not null := mm/12.0;

    d      constant interval_days_t   not null := interval_days  (ts_max, ts_min);
    dd     constant double precision  not null := (interval_mm_dd_ss(d)).dd;

    yd     constant double precision  not null := dd/365.2425;

    ratio  constant double precision  not null := abs(ym -yd)/greatest(ym, yd);
  begin
    assert ratio < 0.000001, 'Test #8 failure';
  end "Test #8";

end;
$body$;

call do_tests();
