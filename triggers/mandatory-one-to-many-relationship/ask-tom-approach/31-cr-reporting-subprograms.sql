call mgr.set_role('code');

create function code.master_and_details_report()
  returns table(z text)
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

      select array_agg(x order by (x).m) from c2
    );
begin
  case
    when results is not null then
      foreach r in array results loop
        z := rpad(r.m, 7)||'>> ';
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
call mgr.revoke_all_from_public('function', 'code.master_and_details_report()');
call mgr.grant_priv( 'execute', 'function', 'code.master_and_details_report()', 'client');
--------------------------------------------------------------------------------

create type code.join_facts as (m text, ds text[], mk int, m_dk int, dks int[]);
call mgr.revoke_all_from_public('type', 'code.join_facts');
call mgr.grant_priv(   'usage', 'type', 'code.join_facts', 'client');

create function code.decorated_master_and_details_report()
  returns table(z text)
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  d  text;
  r  code.join_facts not null := ('', '{}'::text, 0, 0, '{}'::int[]);

  -- Will be NULL when there are no results
  results constant code.join_facts[] :=
    (
      with
        c1(m, ds, mk, m_dk, dks) as (
          select
            m.v,
            array_agg(d.v order by d.dk),
            mk,
            m.dk,
            array_agg(d.dk order by d.dk)
          from
            data.masters m
            left outer join
            data.details d
            using (mk)
          group by m.v, mk),

        c2(x) as (
          select (m, ds, mk, m_dk, dks)::code.join_facts
          from c1)

      select array_agg(x order by (x).mk) from c2
    );
begin
  case
    when results is not null then
      foreach r in array results loop
        z := rpad(r.m, 7)||'>> ';
        foreach d in array r.ds loop
          d := case
                 when d is null then '<NULL>'
                 else                d
               end;
          z := z||d||', ';
        end loop;
        z := rtrim(rtrim(z), ',');

        z := rpad(z, 50)||
             lpad(r.mk::text,   6)||','||
             lpad(r.m_dk::text, 3)||', '||
             rpad(r.dks::text, 13)||' >> '||
             (r.m_dk = any(r.dks))::text;                 return next;
      end loop;
    else
      z := 'Both "masters" and "details" are empty.';     return next;
  end case;
end;
$body$;
call mgr.revoke_all_from_public('function', 'code.decorated_master_and_details_report()');
call mgr.grant_priv( 'execute', 'function', 'code.decorated_master_and_details_report()', 'client');
