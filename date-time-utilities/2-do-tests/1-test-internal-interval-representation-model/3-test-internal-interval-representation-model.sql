create procedure test_internal_interval_representation_model()
  language plpgsql
as $body$
begin
  call assert_model_ok(interval_parameterization());

  call assert_model_ok(interval_parameterization(
    mm =>       99,
    dd =>      700,
    ss => 83987851.522816));

  call assert_model_ok(interval_parameterization(
    yy => 3.853467));

  call assert_model_ok(interval_parameterization(
    mm => 11.674523));

  call assert_model_ok(interval_parameterization(
    dd => 0.235690));

  call assert_model_ok(interval_parameterization(
    dd => 700.546798));

  call assert_model_ok(interval_parameterization(
    ss => 47243.347200));

  call assert_model_ok(interval_parameterization(
    mm => -0.54,
    dd => 17.4));

  call assert_model_ok(interval_parameterization(
    mm => -0.55,
    dd => 17.4));

  call assert_model_ok(interval_parameterization(
    mm =>  0.11,
    dd => -1));

  call assert_model_ok(interval_parameterization(
    mm =>  0.12,
    dd => -1));

  call assert_model_ok(interval_parameterization(
    dd => 1.2));

  call assert_model_ok(interval_parameterization(
    dd => 0.9));

  call assert_model_ok(interval_parameterization(
    dd => 1,
    hh => -2,
    mi => 24,
    ss => 0));

  call assert_model_ok(interval_parameterization(
    dd => 0,
    hh => 21,
    mi => 36,
    ss => 0));

  call assert_model_ok(interval_parameterization(
    yy =>  19,
    mm => -1,
    dd =>  17,
    hh => -100,
    mi =>  87,
    ss => -76));

  call assert_model_ok(interval_parameterization(
    yy =>  9.7,
    mm => -1.55,
    dd =>  17.4,
    hh => -99.7,
    mi =>  86.7,
    ss => -75.7));

  call assert_model_ok(interval_parameterization(
    yy => -9.7,
    mm =>  1.55,
    dd => -17.4,
    hh =>  99.7,
    mi => -86.7,
    ss =>  75.7));
  end;
$body$;

call test_internal_interval_representation_model();
