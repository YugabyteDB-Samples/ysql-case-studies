create procedure date_time_tests.assert_model_ok(p in dt_utils.interval_parameterization_t)
  set search_path = pg_catalog, date_time_tests, dt_utils, pg_temp
  language plpgsql
as $body$
declare
  i_modeled        constant interval_mm_dd_ss_t not null := interval_mm_dd_ss(p);
  i_from_modeled   constant interval            not null := interval_value(i_modeled);
  i_actual         constant interval            not null := interval_value(p);
  mm_dd_ss_actual  constant interval_mm_dd_ss_t not null := interval_mm_dd_ss(i_actual);

  p_modeled  constant interval_parameterization_t not null := parameterization(i_modeled);
  p_actual   constant interval_parameterization_t not null := parameterization(i_actual);
begin
  -- Belt-and-braces check for mutual consistency among the "interval" utilities.
  assert (i_modeled      ~= mm_dd_ss_actual), 'assert #1 failed';
  assert (p_modeled      ~= p_actual       ), 'assert #2 failed';
  assert (i_from_modeled == i_actual       ), 'assert #3 failed';
end;
$body$;
