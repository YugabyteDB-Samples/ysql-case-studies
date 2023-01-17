/*
  The hardening concept is to revoke privileges from "public" and re-grant them to the
  special global role "clstr$developer". This can be safely granted to all the roles
  that own an application's implementation but, critically, NOT granted to the "client" role.

  It's easy to limit access to the objects in the "information_schema", "mgr", "dt_utils",
  and "extensions" at the level of the entire schema because these objects are not needed at
  run time but serve only to help developers' comprehension "ad hoc" while they work.

  However, many of the objects in "pg_catalog" implement basic SQL features like
  text concatenation, equality comparison, and so on. If all of these features
  are disabled for the client role, it makes life rather hard -- but nevertheless manageable.

  For the tables and views that document the system for the developer, "all" can be revoked from all
  of these from "public".

  The best compromise for "pg_catalog" functions seems to be to revoke access from "public" explicily
  for (very) many objects while leaving "usage" on "pg_catalog" still granted to "public". This allows
  the very few functions and procedures that the "allowlist" specifies still to be executable by
  "public" and therefore by the "client" role. (Notice that there happen to be no "pg_catalog" procedures;
  but nevertheless the codeis written defensively to handle these.)

  This approach is generally preferred to an using "excludelist" approach.
*/;
--------------------------------------------------------------------------------------------------------------
-- Entire schemas.

revoke usage on schema information_schema  from public;
revoke usage on schema mgr                 from public;
revoke usage on schema dt_utils            from public;
revoke usage on schema extensions          from public;

grant  usage on schema information_schema  to   clstr$developer;
grant  usage on schema mgr                 to   clstr$developer;
grant  usage on schema dt_utils            to   clstr$developer;
grant  usage on schema extensions          to   clstr$developer;

--------------------------------------------------------------------------------------------------------------
-- Catalog tables and views.
do $body$
declare
  /*
    The distinct "relkind" values in "pg_catalog" are "r", "v", and "i".
    But indexes are no individually accessible and so aren't goverened by privileges.
  */
  allow_kinds constant "char"[]not null  := array['r'::"char", 'v'::"char"];
  tab text;
begin
  for tab in (
    select c.relname::text
    from pg_class c
    inner join
    pg_namespace n
    on c.relnamespace = n.oid
    where c.relkind = any(allow_kinds)
    and n.nspname = 'pg_catalog')
  loop
    execute format('revoke all    on table %I from public',          tab);
    execute format('grant  select on table %I to   clstr$developer', tab);
  end loop;
end;
$body$;

-- Types (excluding base types and pseudotypes).
do $body$
declare
  typ text;
  exclude_kinds constant "char"[]not null  := array['b'::"char", 'p'::"char"];
begin
  -- Types.
  for typ in (
    select t.typname::text
    from pg_type t
    inner join
    pg_namespace n
    on t.typnamespace = n.oid
    where t.typtype != all(exclude_kinds)
    and n.nspname = 'pg_catalog')
  loop
    execute format('revoke all   on type %I from public',          typ);
    execute format('grant  usage on type %I to   clstr$developer', typ);
  end loop;
end;
$body$;

--------------------------------------------------------------------------------------------------------------
/*
  The following block does for "pg_catalog" functions what the block above does for tables and views
  in that schema. You can try it. You'll notice that many  operations that you take for granted cuase
  an error when you're connected as the "client" role. Try this:

    select 1.2 - 2.3;

  It fails with the 42501 error:

    permission denied for function numeric_sub

  It's straightforward to avoid this by extending the "allowlist" array. You might think that
  this is a tedious effort. But doing this is nothing other than adhering to the letter of the
  principle of least privilege. It says "Start with nothing and grant exactly and only what you
  need." The alternative is simply to start with (w.r.t. the functions in the pg_catalog" schema)
  approaching three thousand privileges when you need only a handful) and to reason that not
  a single one of the unneeded privileges is harmful.

  If you don't like this, just give up on the principle of least privilege and comment the block out.

  The "allowlist" elements below are simply examples. It's hard to see how any harm could follow
  from allowing the "client" role to execute any of these. However (see the "hard-shell" case-study)
  if the client-facing API is entirely text in, text out subprograms, encoded as JSON, it's hard see
  too haow any in the list (even text concatenation) would be useful.

  For "oid::regprocedure",
  see https://postgrespro.com/list/thread-id/1914117 (Tom Lane, 04-Mar-2005).
  and https://www.postgresql.org/docs/11/datatype-oid.html
*/

/*
  Experiment by commenting this block out.
   Will need to re-create the cluster after commenting IN or OUT.

  When commented out, move "pg.txt" to:
    "xfer-schema-grants-from-public-to-clstr-developer-choices/pg-entire-schemas-and-catalog-views-revoked-from-public.txt"

  Else, move "pg.txt" to:
    "xfer-schema-grants-from-public-to-clstr-developer-choices/pg-everything-except-a-few-innocent-catalog-functions-revoked-from-public"
*/;
--/*
  do $body$
  declare
    kind text;
    proc text;
    candidates constant "char"[] := array['f'::"char", 'a'::"char", 'w'::"char", 'p'::"char"];
    allowlist constant text[] not null := array[
      'current_database',
      'version',
      'pg_typeof',
      'int8',         -- needed for "select 'dog' limit 50"
      'int4out',      -- implements ::int
      'int4pl',       -- implements the + operator between int values
      'int4mi',       -- implements the - operator between int values
      'int4eq',       -- implements the = operator between int values
      'numeric_out',  -- implements ::numeric
      'numeric',      -- needed for "select ('3'::int + 5)::numeric + 7.6"
      'numeric_add',  -- implements the + operator between numeric values
      'numeric_eq',   -- implements the = operator between numeric values
      'float8',       -- implements ::double precision
      'floatpl',      -- implements implements the + operator between double precision values
      'text',         -- implements ::text
      'textin',       -- needed for "select (1.3::text)"
      'textcat',      -- implements the || operator
      'texteq',       -- implements the = operator between text values
      'textlike',     -- implements the "like" operator between text values
      'lpad', 'rpad'
      ];
  begin
    -- Ensure known starting state.
    for kind, proc in (
      select
        case p.prokind
          when 'f' then 'function'
          when 'a' then 'function'
          when 'w' then 'function'
          when 'p' then 'procedure'
        end,
        p.oid::regprocedure::text
      from pg_proc p inner join pg_namespace n on p.pronamespace = n.oid
      where n.nspname = 'pg_catalog'
      and p.prokind = any(candidates))
    loop
      execute format('grant execute on %s pg_catalog.%s to public',  kind, proc);
    end loop;

    for kind, proc in (
      select
        case p.prokind
          when 'f' then 'function'
          when 'a' then 'function'
          when 'w' then 'function'
          when 'p' then 'procedure'
        end,
        p.oid::regprocedure::text
      from pg_proc p inner join pg_namespace n on p.pronamespace = n.oid
      where n.nspname = 'pg_catalog'
      and ((p.proname)::text != all (allowlist))
      and p.prokind = any(candidates))
    loop
      execute format('revoke execute on %s pg_catalog.%s from public',           kind, proc);
      execute format('grant  execute on %s pg_catalog.%s to   clstr$developer',  kind, proc);
    end loop;
  end;
  $body$;
--*/;
