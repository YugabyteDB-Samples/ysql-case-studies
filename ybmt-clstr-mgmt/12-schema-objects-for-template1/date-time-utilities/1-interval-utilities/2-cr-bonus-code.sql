create function dt_utils.interval_mm_dd_ss_as_text(i in interval)
  returns text
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  mm_dd_ss constant dt_utils.interval_mm_dd_ss_t not null := dt_utils.interval_mm_dd_ss(i);
  ss_text  constant text                         not null := ltrim(to_char(mm_dd_ss.ss, '9999999999990.999999'));
begin
  return
    mm_dd_ss.mm::text||' months ' ||
    mm_dd_ss.dd::text||' days '   ||
    ss_text          ||' seconds' ;
end;
$body$;
revoke all     on function dt_utils.interval_mm_dd_ss_as_text(interval) from public;
grant  execute on function dt_utils.interval_mm_dd_ss_as_text(interval) to   public;

create function dt_utils.parameterization_as_text(i in interval)
  returns text
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  p        constant dt_utils.interval_parameterization_t not null := dt_utils.parameterization(i);
  ss_text  constant text                                 not null := ltrim(to_char(p.ss, '9999999999990.999999'));
begin
  return
    p.yy::text||' years '   ||
    p.mm::text||' months '  ||
    p.dd::text||' days '    ||
    p.hh::text||' hours '   ||
    p.mi::text||' minutes ' ||
    ss_text   ||' seconds';
end;
$body$;
revoke all     on function dt_utils.parameterization_as_text(interval) from public;
grant  execute on function dt_utils.parameterization_as_text(interval) to   public;

create function dt_utils.parameterization_as_text(i in dt_utils.interval_mm_dd_ss_t)
  returns text
  set search_path = dt_utils, pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  p        constant dt_utils.interval_parameterization_t not null := dt_utils.parameterization(i);
  ss_text  constant text                                 not null := ltrim(to_char(p.ss, '9999999999990.999999'));
begin
  return
    p.yy::text||' years '   ||
    p.mm::text||' months '  ||
    p.dd::text||' days '    ||
    p.hh::text||' hours '   ||
    p.mi::text||' minutes ' ||
    ss_text   ||' seconds';
end;
$body$;
revoke all     on function dt_utils.parameterization_as_text(dt_utils.interval_mm_dd_ss_t) from public;
grant  execute on function dt_utils.parameterization_as_text(dt_utils.interval_mm_dd_ss_t) to   public;

-- Self-tests
do $body$
declare
  t1 constant text not null :=
    dt_utils.interval_mm_dd_ss_as_text('2 years 3 months 999 days 77 hours 53 min 17.123456 secs'::interval);

  t2 constant text not null :=
    dt_utils.parameterization_as_text('2 years 3 months 999 days 77 hours 53 min 17.123456 secs'::interval);

  t3 constant text not null :=
    dt_utils.parameterization_as_text((67, 999, 280397.123456)::dt_utils.interval_mm_dd_ss_t);
begin
  assert t1 = '27 months 999 days 280397.123456 seconds',                        'Unexpected t1';
  assert t2 = '2 years 3 months 999 days 77 hours 53 minutes 17.123456 seconds', 'Unexpected t2';
  assert t3 = '5 years 7 months 999 days 77 hours 53 minutes 17.123456 seconds', 'Unexpected t3';
end;
$body$;
