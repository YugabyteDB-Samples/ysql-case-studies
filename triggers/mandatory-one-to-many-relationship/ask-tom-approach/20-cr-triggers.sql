set role d4$data;
/*
  Workaround for limitation that YB does not yet support
    "referencing old table as old_details"
  for an "after statement" trigger.
*/
create function data.details_after_row()
  returns trigger
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  mk_ constant int not null := old.mk;
begin
  create temporary table if not exists old_details(mk int);
  insert into old_details(mk) values(mk_);
  return old;
end;
$body$;

create trigger details_after_row
  after delete
  on data.details
  for each row
execute function data.details_after_row();

create type data.mk_mdk_ddks as (mk int, m_dk int, d_dks int[]);

create function data.details_after_statement()
  returns trigger
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  mk_ int;
  dk_ int;
  v_  text;

  affected_mks constant int[] := (
    with c(mk) as (select distinct mk from old_details)
    select array_agg(mk) from c);

  r                data.mk_mdk_ddks   not null := (0, 0, '{}'::int[]);
  results constant data.mk_mdk_ddks[] :=
    (
      with
        c1 (mk, m_dk, d_dks) as (
          select
            mk,
            m.dk,
            array_agg(d.dk order by d.dk)
          from
            data.masters m
            left outer join
            data.details d
            using (mk)
          where mk = any(affected_mks)
          group by 1),

        c2 (x) as (
          select (mk, m_dk, d_dks)
          from c1)

      select array_agg(x order by x) from c2
    );
begin
  if results is null then
    /*
      This means that there are no "masters" rows for any of the
      deleted "details" rows. This will the case after a (cascade)
      "delete from masters where...". Here, the "on commit" check
      of the "details_fk" constraint on "masters"check will succeed.
    */
    return old;
  end if;

  foreach r in array results loop
    if (
         r.d_dks = array[]::int[] or
         r.d_dks = array[null]::int[]
       )
    then
      /*
        At least one existing  "masters" row has no "details" rows.
        No rescue is possible. Let the "on commit" check of the
        "details_fk" constraint on "masters" take responsiblity for
        the test and fail the txn.
      */
      return old;
    end if;

    if not (r.m_dk = any(r.d_dks)) then
      /*
        "masters" row has no parent in "details".
        Would not be here unless there's at least one surviving "details"
        row for this master. Re-parent the "masters" row to the first
        of these.

        Informally: do the "twizzle".
      */
      update data.masters set dk = r.d_dks[1] where mk = r.mk;
    end if;
  end loop;

  return old;
end;
$body$;

/*
  The natural approach is to use "referencing old table as old_details"
  so that the RDMBS populates is automaically. However, YB (at least
  through YB-2.15.3.2) doesn't yet support this. See

    https://github.com/yugabyte/yugabyte-db/issues/1668

  We the therefore need to create and populate the "old_details"
  temporary table with explicit application code.

  See "create trigger details_after_row" above and the trigger function
  that it uses.
*/;
create trigger details_after_statement
  after delete
  on data.details
  /* referencing old table as old_details */
  for each statement
execute function data.details_after_statement();
