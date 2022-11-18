-- Acceptable values are between "-12:00:00" and "14:00:00" with seconds cpt = zero
do $body$
begin
  begin
    call assert_acceptable_timezone_interval(make_interval(hours=>11));
  exception when others then
    assert false, 'test_assert_approved_timezone_name(): logic error #1.';
  end;

  begin
    call assert_acceptable_timezone_interval(make_interval(hours=>23));
    assert false, 'test_assert_approved_timezone_name(): logic error #2.';
  exception when invalid_parameter_value then
    null;
  end;

  begin
    call assert_acceptable_timezone_interval(make_interval(secs=>13.12345));
    assert false, 'test_assert_approved_timezone_name(): logic error #3.';
  exception when invalid_parameter_value then
    null;
  end;
end;
$body$;
