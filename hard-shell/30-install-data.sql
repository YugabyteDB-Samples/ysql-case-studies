call mgr.set_role('data');
call mgr.revoke_all_from_public('schema', 'data');
call mgr.grant_priv(   'usage', 'schema', 'data', 'code');

-- For unit testing code and ad hoc demo code.
call mgr.grant_priv('usage', 'schema', 'data', 'qa');
--------------------------------------------------------------------------------

create table data.masters(
  mk uuid
    default extensions.gen_random_uuid()
    constraint masters_pk primary key,
  v text
    not null
    constraint masters_v_unq unique
    constraint masters_v_chk check(length(v) between 3 and 10));

call mgr.revoke_all_from_public(                      'table', 'data.masters');
call mgr.grant_priv('select, insert, update, delete', 'table', 'data.masters', 'code');
call mgr.grant_priv('select, insert, update, delete', 'table', 'data.masters', 'qa');
------------------------------------------------------------

create table data.details(
  mk uuid,
  dk
    uuid default extensions.gen_random_uuid(),
  v text
    not null
    constraint details_v_chk check(length(v) between 3 and 20),

  constraint details_pk primary key(mk, dk),

  constraint details_fk foreign key(mk)
    references data.masters(mk)
    on delete cascade,

  constraint details_mk_v_unq unique(mk, v));

call mgr.revoke_all_from_public(                      'table', 'data.details');
call mgr.grant_priv('select, insert, update, delete', 'table', 'data.details', 'code');
call mgr.grant_priv('select, insert, update, delete', 'table', 'data.details', 'qa');
