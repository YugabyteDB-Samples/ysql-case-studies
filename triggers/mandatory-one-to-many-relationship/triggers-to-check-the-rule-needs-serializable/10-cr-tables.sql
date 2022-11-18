call mgr.set_role('data');
call mgr.revoke_all_from_public('schema', 'data');
call mgr.grant_priv(   'usage', 'schema', 'data', 'code');

create table data.masters(
  mk uuid default extensions.gen_random_uuid()
    constraint masters_pk primary key,

  v text not null
    constraint masters_v_unq unique
);

call mgr.revoke_all_from_public(              'table', 'data.masters');
call mgr.grant_priv('select, insert, delete', 'table', 'data.masters', 'code');

create table data.details(
  mk uuid,
  dk uuid default extensions.gen_random_uuid(),
  v  text not null,

  constraint details_pk primary key(mk, dk),

  constraint details_fk foreign key(mk)
    references data.masters(mk)
    on delete cascade
    initially deferred,

  constraint details_mk_v_unq unique(mk, v)
);

call mgr.revoke_all_from_public(              'table', 'data.details');
call mgr.grant_priv('select, insert, delete', 'table', 'data.details', 'code');
