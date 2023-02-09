create function date_time_tests.interval_mm_dd_ss(p in interval_parameterization_t)
  returns interval_mm_dd_ss_t
  set search_path = pg_catalog, dt_utils, pg_temp
  language plpgsql
as $body$
declare
  mm_per_yy               constant double precision not null := 12.0;
  dd_per_mm               constant double precision not null := 30.0;
  ss_per_dd               constant double precision not null := 24.0*60.0*60.0;
  ss_per_hh               constant double precision not null := 60.0*60.0;
  ss_per_mi               constant double precision not null := 60.0;

  mm_trunc                constant int              not null := trunc(p.mm);
  mm_remainder            constant double precision not null := p.mm - mm_trunc::double precision;

  -- This is a quirk.
  mm_out                  constant int              not null := trunc(p.yy*mm_per_yy) + mm_trunc;

  dd_real_from_mm         constant double precision not null := mm_remainder*dd_per_mm;

  dd_int_from_mm          constant int              not null := trunc(dd_real_from_mm);
  dd_remainder_from_mm    constant double precision not null := dd_real_from_mm - dd_int_from_mm::double precision;

  dd_int_from_user        constant int              not null := trunc(p.dd);
  dd_remainder_from_user  constant double precision not null := p.dd - dd_int_from_user::double precision;

  dd_out                  constant int              not null := dd_int_from_mm + dd_int_from_user;

  d_remainder             constant double precision not null := dd_remainder_from_mm + dd_remainder_from_user;

  ss_out                  constant double precision not null := d_remainder*ss_per_dd +
                                                                p.hh*ss_per_hh +
                                                                p.mi*ss_per_mi +
                                                                p.ss;
begin
  return (mm_out, dd_out, ss_out)::interval_mm_dd_ss_t;
end;
$body$;
