/*
  This is needed so that an anonymous block can do a simple equality test between
  two "text" values when authorized as the role with the nickname "client".

  This is because, very much by design, the "client" role cannot execute any functions
  or procedures in pg_catalog but is  meant to use ONLY the subprograms that are owned
  by "ordinary" roles than *can* execute these "system" functions.
*/
create function code.text_equals(t1 in text, t2 in text)
  returns boolean
  security definer
  set search_path = pg_catalog, pg_temp
  language sql
as $body$
  select (t1 = t2);
$body$;
call mgr.revoke_all_from_public('function', 'code.text_equals(text, text)');
call mgr.grant_priv( 'execute', 'function', 'code.text_equals(text, text)', 'client');
