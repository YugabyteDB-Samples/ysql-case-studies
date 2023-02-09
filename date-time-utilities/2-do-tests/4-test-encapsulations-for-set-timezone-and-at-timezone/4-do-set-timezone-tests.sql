-- Force the use of qualified idenitifiers
set search_path = pg_catalog, pg_temp;

do $body$
declare
  tz_in  text not null := '';
  tz_out text not null := '';

  good_zones constant text[] := array[
    'UTC',
    'Asia/Kathmandu',
    'Europe/Amsterdam'];
begin
  foreach tz_in in array good_zones loop
    call ext_tz_names.set_timezone(tz_in);
    show timezone into tz_out;
    declare
      msg constant text not null := tz_in||' assert failed';
    begin
      assert tz_out = tz_in, msg; 
    end;
  end loop;

  begin
    call ext_tz_names.set_timezone('Bad');
    assert false, 'Logic error'; 
  exception when invalid_parameter_value then
    declare
      msg  text not null := '';
      hint text not null := '';
    begin
      get stacked diagnostics
        msg     = message_text,
        hint    = pg_exception_hint;

      /*
      raise info '%', msg;
      raise info '%', hint;
      */
    end;
  end;
end;
$body$;

do $body$
declare
  tz_out text not null := '';
begin
  call ext_tz_names.set_timezone(make_interval(hours=>-7));
  show timezone into tz_out;
  assert tz_out= '<-07>+07', 'Assert <-07>+07 failed';

  call ext_tz_names.set_timezone(make_interval(hours=>-5, mins=>45));
  show timezone into tz_out;
  assert tz_out= '<-04:15>+04:15', 'Assert <-04:15>+04:15 failed';

  begin
    call ext_tz_names.set_timezone(make_interval(hours=>19));
    assert false, 'Logic error'; 
  exception when invalid_parameter_value then
    declare
      msg  text not null := '';
      hint text not null := '';
    begin
      get stacked diagnostics
        msg     = message_text,
        hint    = pg_exception_hint;

      /*
      raise info '%', msg;
      raise info '%', hint;
      */
    end;
  end;
end;
$body$;
