/*
  Use "left outer join" to show any master row with no details
  (in violation of the "mandatory 1:m" rule).

  \t off
  select mk, m.v, d.v
  from
  data.masters m
  left outer join
  data.details d
  using (mk)
  order by 1, 2;
  \t on
*/;
--------------------------------------------------------------------------------

create function code.master_and_details_report()
  returns table(z text)
  stable
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  d  text;
  r  code.m_and_ds not null := ('', '{}');

  -- Will be NULL when there are no results
  results constant code.m_and_ds[] :=
    (
      with
        c1(m, ds) as (
          select
            m.v, array_agg(d.v order by d.v)
          from
            data.masters m
            left outer join
            data.details d
            using (mk)
          group by 1),

        c2(x) as (
          select (m, ds)::code.m_and_ds
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
revoke execute on function code.master_and_details_report() from public;
grant  execute on function code.master_and_details_report() to   d5$client;
