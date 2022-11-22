set role d2$qa;

create schema qa_code authorization d2$qa;

--------------------------------------------------------------------------------

create procedure qa_code.insert_master_and_details(this in code.m_and_ds)
  security invoker
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  new_mk      uuid    not null := '9919f9cd-ae06-4c02-a9e6-256bc56b3b20';
  d           text    not null := '';
  new_master  boolean not null := true;
begin
  begin
    insert into data.masters(v) values(this.m) returning mk into new_mk;
  exception when unique_violation then
    select mk into new_mk from data.masters where v = this.m;
    new_master := false;
  end;

  if cardinality(this.ds) > 0 then
    with c as (
      select (new_mk, this.ds)::code_helpers.mk_and_ds as v)
    insert into data.details(mk, v)
    select (c.v).mk, arr.d
    from c cross join lateral unnest((c.v).ds) as arr(d);
  end if;
end;
$body$;

revoke all on procedure qa_code.insert_master_and_details(code.m_and_ds) from public;

--------------------------------------------------------------------------------

create function qa_code.master_and_details_report_all_rows(
  out master text,
  out details text[])
  returns setof record

  stable
  security invoker
  set search_path = pg_catalog, pg_temp
  language sql
as $body$
  select
    m.v                          as master,
    array_agg(d.v order by d.v)  as details
  from
    data.masters m
    left outer join
    data.details d
    using (mk)
  group by 1
  order by 1;
$body$;

revoke all on function qa_code.master_and_details_report_all_rows() from public;

--------------------------------------------------------------------------------

create function qa_code.master_and_details_report_one_row(mv_in in text)
  returns code.m_and_ds

  stable
  security invoker
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  m_and_ds code.m_and_ds;
begin
  select m.v, array_agg(d.v order by d.v)
  into strict m_and_ds
  from
    data.masters m
    left outer join
    data.details d
    using (mk)
  where m.v = mv_in
  group by 1
  order by 1;

  return m_and_ds;
end;
$body$;

revoke all on function qa_code.master_and_details_report_one_row(text) from public;
