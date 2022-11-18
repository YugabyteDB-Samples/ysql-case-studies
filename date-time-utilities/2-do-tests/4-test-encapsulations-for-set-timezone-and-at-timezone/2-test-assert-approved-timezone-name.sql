do $body$
begin
  begin
    -- "America/Anchorage" is good.
    call assert_approved_timezone_name('America/Anchorage');
  exception when others then
    assert false, 'test_assert_approved_timezone_name(): logic error #1.';
  end;

  begin
    -- "Iceland" is listed in "pg_timezone_names".
    -- but the List of tz database time zones (https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
    -- has it with status = 'Deprecated',
    call assert_approved_timezone_name('Iceland');
    assert false, 'test_assert_approved_timezone_name(): logic error #2.';
  exception when invalid_parameter_value then
    null;
  end;
end;
$body$;
