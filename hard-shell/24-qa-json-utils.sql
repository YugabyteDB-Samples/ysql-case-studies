set role d2$qa;

\t on
\pset null '<NULL>'

----------------------------------------------------------------------------------------------------
select  mgr.rule_off('POSITIVE TESTS for json_utils.json_object_keys_ok()');

select qa_json_utils.json_object_keys_ok_outcome(
  'OK',
  '{"m": "Fred"}',
  $$('m', 'string', true)$$);

select qa_json_utils.json_object_keys_ok_outcome(
  'OK',
  '{"m": "Fred"}',
  $$('m', 'string', true), ('m', 'null', true)$$);

select qa_json_utils.json_object_keys_ok_outcome(
  'OK',
  '{"m": "Fred", "ds": []}',
  $$('m', 'string', true), ('ds', 'array', false)$$);

select qa_json_utils.json_object_keys_ok_outcome(
  'OK',
  '{"m": "Fred"}',
  $$('m', 'string', true), ('ds', 'array', false)$$);

select qa_json_utils.json_object_keys_ok_outcome(
  'OK',
  '{"m": "Fred", "ds": ["x", "y"]}',
  $$('m', 'string', true), ('ds', 'array', false)$$);

select qa_json_utils.json_object_keys_ok_outcome(
  'OK',
  '{"a": "a", "b": 42, "c": true, "d": "d"}',
  $$('a', 'string', true), ('b', 'number', true), ('c', 'boolean', true), ('d', 'string', false)$$);

select qa_json_utils.json_object_keys_ok_outcome(
  'OK',
  '{"a": "a", "c": true, "d": "d"}',
  $$('a', 'string', true), ('b', 'number', false), ('c', 'boolean', true), ('d', 'string', false)$$);

----------------------------------------------------------------------------------------------------
select  mgr.rule_off('NEGATIVE TESTS for json_utils.json_object_keys_ok()');

select qa_json_utils.json_object_keys_ok_outcome(
  'Input is SQL NULL',
  null,
  $$('m', 'string', true)$$);

select qa_json_utils.json_object_keys_ok_outcome(
  'Semicolon following "m"',
  '{"m"; "Fred"}',
  $$('m', 'string', true)$$);

select qa_json_utils.json_object_keys_ok_outcome(
  'Input is JSON null',
  'null',
  $$('m', 'string', true)$$);

select qa_json_utils.json_object_keys_ok_outcome(
  'Input JSON is the scalar 42',
  '42',
  $$('m', 'string', true)$$);

select qa_json_utils.json_object_keys_ok_outcome(
  'Input is empty {}',
  '{}',
  $$('m', 'string', true)$$);

select qa_json_utils.json_object_keys_ok_outcome(
  $$Value for "m" is 'number'$$,
  '{"m": 42, "ds": ["x", "y"]}',
  $$('m', 'string', true), ('ds', 'array', false)$$);

select qa_json_utils.json_object_keys_ok_outcome(
  $$Value for "ds" is 'string'$$,
  '{"m": "Joan", "ds": "x"}',
  $$('m', 'string', true), ('ds', 'array', false)$$);

select qa_json_utils.json_object_keys_ok_outcome(
  'Bad key "x"',
  '{"a": "a", "b": 42, "x": true, "d": "d"}',
  $$('a', 'string', true), ('b', 'number', true), ('c', 'boolean', true), ('d', 'string', false)$$);

select qa_json_utils.json_object_keys_ok_outcome(
  'Extra key "e"',
  '{"a": "a", "b": 42, "c": true, "d": "d", "e": "e"}',
  $$('a', 'string', true), ('b', 'number', true), ('c', 'boolean', true), ('d', 'string', false)$$);

select qa_json_utils.json_object_keys_ok_outcome(
  '"m" is missing',
  '{"ds": []}',
  $$('m', 'string', true), ('ds', 'array', false)$$);

\pset null ''
\t off
