create type          trg_firing_order.mk_and_ds  as (mk int, ds text[]);
create type          trg_firing_order.m_and_ds   as (m text, ds text[]);

create procedure trg_firing_order.upsert_master_insert_details(
  m_and_ds in trg_firing_order.m_and_ds)
  security definer
  set search_path = pg_catalog, trg_firing_order, pg_temp
  language plpgsql
as $body$
declare
  new_mk int not null := 0;
begin
  begin
    insert into masters(v) values(m_and_ds.m) returning mk into new_mk;
  exception when unique_violation then
    select mk into new_mk from masters where v = m_and_ds.m;
  end;

  with c(v) as (
    select (new_mk, m_and_ds.ds)::mk_and_ds)
  insert into details(mk, v)
  select (c.v).mk, arr.d
  from c cross join lateral unnest((c.v).ds) as arr(d);
end;
$body$;
--------------------------------------------------------------------------------

create procedure trg_firing_order.update_one_detail(old_v in text, new_v in text)
  security definer
  set search_path = pg_catalog, trg_firing_order, pg_temp
  language plpgsql
as $body$
begin
  update details set v = new_v where v = old_v;
end;
$body$;
--------------------------------------------------------------------------------

create procedure trg_firing_order.delete_specified_details(dvs variadic text[] = null)
  security definer
  set search_path = pg_catalog, trg_firing_order, pg_temp
  language plpgsql
as $body$
begin
  case
    when dvs is null then
      null;
    else
      delete from details where v = any(dvs);
  end case;
end;
$body$;
--------------------------------------------------------------------------------

create procedure trg_firing_order.cascade_delete_specified_masters(mvs variadic text[] = null)
  security definer
  set search_path = pg_catalog, trg_firing_order, pg_temp
  language plpgsql
as $body$
begin
  case
    when mvs is null then
      delete from masters;
    else
      delete from masters where v = any(mvs);
  end case;
end;
$body$;
--------------------------------------------------------------------------------

create function trg_firing_order.master_and_details_report()
  returns table(z text)
  stable
  security definer
  set search_path = pg_catalog, trg_firing_order, pg_temp
  language plpgsql
as $body$
declare
  d  text;
  r  m_and_ds not null := ('', '{}');

  -- Will be NULL when there are no results
  results constant m_and_ds[] :=
    (
      with
        c1(m, ds) as (
          select
            m.v, array_agg(d.v order by d.v)
          from
            masters m
            left outer join
            details d
            using (mk)
          group by 1),

        c2(x) as (
          select (m, ds)::m_and_ds
          from c1)

      select array_agg(x order by x) from c2
    );
begin
  case
    when results is not null then
      foreach r in array results loop
        z := r.m||' >> ';
        foreach d in array r.ds loop
          d := case
                 when d is null then '<NULL>'
                 else                d
               end;
          z := z||d||', ';
        end loop;
        z := rtrim(rtrim(z), ',');                        return next;
      end loop;
    else
      z := 'Both "masters" and "details" are empty.';     return next;
  end case;
end;
$body$;
