/*
-- Solves this problem:

  with x as (select -'09:30'::interval as i)
  select
    i::text,
    to_char(i, 'hh24:mi'),
    ext_tz_names.to_char_interval(i)
  from x;

-- This is the result.
--      i     | to_char | to_char_interval 
-- -----------+---------+------------------
--  -09:30:00 | -09:-30 | -09:30
--
-- The ::text typecast shows the seconds. But they're always "00".
-- The bare "to_char()" is ugly and hard to read.
--
-- Also asserts the the scendos cpt is ZERO.
*/;

create function ext_tz_names.to_char_interval(i in interval)
  returns text
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  hh          int     not null := extract(hour   from i);
  mi          int     not null := extract(minute from i);
  ss constant int     not null := extract(second from i);
  positive    boolean not null := false;
begin
  assert ss = 0, 'to_char_interval: assert failed: ss cpt <> 0';

  case
    when hh >= 0 and mi >= 0 then
      positive := true;
    when hh <= 0 and mi <= 0 then
      positive := false;
      hh := -hh;
      mi := -mi;
    else
      declare
        msg constant text not null :=
          'to_char_interval: assert failed: hh cpt has different sign from mi cpt: '||i::text;
      begin
        assert false, msg;
      end;
  end case;
  declare
    v1 constant text not null := ltrim(to_char(hh, '09')||':'||ltrim(to_char(mi, '09')));
    v2 constant text not null :=
      case positive
        when true  then lpad(v1,      6)
        when false then lpad('-'||v1, 6)
      end;
  begin
    return v2;
  end;
end;
$body$;

call mgr.revoke_all_from_public('function', 'ext_tz_names.to_char_interval(interval)');
call mgr.grant_priv( 'execute', 'function', 'ext_tz_names.to_char_interval(interval)', 'public');


/*
--Basic test.
\t on
select ext_tz_names.to_char_interval( '10:00'::interval);
select ext_tz_names.to_char_interval( '09:30'::interval);
select to_char_interval( '00:00'::interval);
select ext_tz_names.to_char_interval('-09:30'::interval);
select ext_tz_names.to_char_interval('-10:00'::interval);
\t off
*/;
