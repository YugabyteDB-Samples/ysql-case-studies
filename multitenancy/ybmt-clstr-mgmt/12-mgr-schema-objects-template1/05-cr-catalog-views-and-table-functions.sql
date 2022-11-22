create view mgr.roles(is_super, name, oid) as
select
  rolsuper,
  rolname::text,
  oid
from pg_roles
where rolname !~ '^pg_'
and   rolname !~ '^yb_'
and   rolname !~ 'PG-SYSTEM'
and has_database_privilege(rolname, current_database(), 'connect');

grant select on table mgr.roles to public;
----------------------------------------------------------------------------------------------------

create view mgr.dbs(name, owner, comment) as
select
  d.datname,
  r.rolname,
  c.description
from
  pg_database d
  inner join pg_roles r
  on d.datdba = r.oid
  inner join pg_shdescription c
  on d.oid = c.objoid
where c.classoid = 1262;

grant select on table mgr.dbs to public;
----------------------------------------------------------------------------------------------------

create view mgr.schemas(name, owner, oid) as
select
  nspname::text,
  nspowner,
  oid
from pg_namespace
where
  nspname::text like 'pg_temp%' or
  not (nspname::text = 'information_schema' or nspname::text like 'pg%'or nspname::text like 'yb%');

grant select on table mgr.schemas to public;
----------------------------------------------------------------------------------------------------

create view mgr.roles_and_schemas(rank, is_super, name, schemas) as
with c(rank, is_super, r_name, s_name) as (
  select
    case r.is_super
      when true then 0
      else           1
    end,
    r.is_super,
    r.name,
    s.name
  from
    mgr.roles r
    left outer join
    mgr.schemas s
    on s.owner = r.oid)
select
  rank,
  is_super,
  r_name,
  array_agg(s_name order by s_name)::text
from c
group by rank, is_super, r_name;

grant select on table mgr.roles_and_schemas to public;
----------------------------------------------------------------------------------------------------

create function mgr.granted_roles(r_name in text)
  returns text[]
  security invoker
  set search_path = pg_catalog, pg_temp
  language sql
as $body$
  with c(a) as (
    select array
      (
        select r1.rolname
        from pg_auth_members m inner join pg_roles r1 on m.roleid = r1.oid
        where m.member = r2.oid
      )
    from pg_roles r2
    where r2.rolname = r_name::name)
  select
    case
      when a = '{}'::name[] then '{NULL}'::text[]
      else                       a       ::text[]
    end
  from c;
$body$;

grant execute on function mgr.granted_roles(text) to public;
----------------------------------------------------------------------------------------------------

create function mgr.roles_and_schemas()
  returns table(z text)
  stable
  security invoker
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  v_super    text;
  v_name     text   not null := '';
  v_schemas  text[] not null := '{}';
begin
  z :=
    rpad('super?',         8)||
    rpad('owner',         18)||
    rpad('schemas',       32)||
         'granted roles';                                 return next;

  z :=
    rpad('-',  6, '-')||'  '||
    rpad('-', 16, '-')||'  '||
    rpad('-', 30, '-')||'  '||
    rpad('-', 30, '-');                                   return next;

  for v_super, v_name, v_schemas in (
    select
      case
        when is_super then 'super'
        else               ''
      end,
      name,
      schemas
    from mgr.roles_and_schemas
    order by rank, name)
  loop
    declare
      g      text not null := '';
      g_list text not null := '';
      s      text not null := '';
      s_list text not null := '';
    begin
      for g in (
        with grs(gr) as (select unnest(mgr.granted_roles(v_name)) order by 1)
          select
            case
              when gr is not null then gr
              else                     ''
            end
          from grs)
      loop
        g_list := case g_list
                    when '' then g
                    else    g_list||', '||g
                  end;
      end loop;

      for s in (
        with schemas(sch) as (select unnest(v_schemas) order by 1)
          select
            case
              when sch is not null then sch
              else                      ''
            end
          from schemas)
      loop
        s_list := case s_list
                    when '' then s
                    else    s_list||', '||s
                  end;
      end loop;

      z :=
        rpad(v_super,        8)||
        rpad(v_name,        18)||
        rpad(s_list,        32)||
             g_list;                                      return next;
    end;
  end loop;
end;
$body$;

grant execute on function mgr.roles_and_schemas() to public;
----------------------------------------------------------------------------------------------------

create view mgr.schema_objects(oid, name, schema, catalog, owner, kind, security, volatility, settings) as
  with o(oid, name, schema_oid, catalog, owner_oid, kind, security, volatility, settings) as
    (
    select
      oid,
      relname,
      relnamespace,
      'pg_class',
      relowner,
        case relkind
          when 'r' then 'ordinary-table'
          when 'v' then 'view'
          when 'i' then 'index'
          when 'S' then 'sequence'
          when 'c' then 'composite-type'
          else          'other'
        end,
        null,
        null,
        null::text[]
    from pg_class
    -- Filter out the row that's automatically generated as the partner
    -- to a manually created composite type.
    where relkind <> 'c'

    union all
      select
        t.oid,
        t.typname,
        t.typnamespace,
        'pg_type',
        t.typowner,
        'composite-type',
        null,
        null,
        null::text[]
      from
        pg_type t
        inner join
        pg_class c
        on t.typname = c.relname and t.typnamespace = c.relnamespace
      where t.typtype ='c'
      -- Filter out the row that's automatically generated as the partner
      -- to a manually created table or manually created view - or even a sequence!.
      and not (c.relkind = 'r' or c.relkind = 'v' or c.relkind = 'S')

    union all
      select
        oid,
        typname,
        typnamespace,
        'pg_type',
        typowner,
        case typtype
          when 'd' then 'domain'
          when 'e' then 'enum'
          else          'other'
        end,
        null,
        null,
        null::text[]
      from pg_type t
      where (typtype = 'd' or typtype = 'e')

    union all
      select
        oid,
        proname,
        pronamespace,
        'pg_proc',
        proowner,
        case prokind
          when 'f' then 'function'
          when 'p' then 'procedure'
          else          'other'
        end,
        case
          when prosecdef then 'definer'
          else                null
        end,
        case provolatile
          when 'i' then 'immutable'
          when 's' then 'stable'
          when 'v' then null
        end,
        proconfig
      from pg_proc
    )
select
  o.oid,
  o.name,
  s.name,
  catalog,
  r.rolname,
  o.kind,
  o.security,
  o.volatility,
  o.settings
from
  o
  inner join
  mgr.schemas s
  on o.schema_oid = s.oid
  inner join pg_roles r
  on o.owner_oid = r.oid
  where s.name <> 'extensions';

grant select on table mgr.schema_objects to public;
----------------------------------------------------------------------------------------------------

create view mgr.triggers(name, tab_name, tab_schema, tab_owner, definition) as
with
  relations(name, schema, owner, oid)
  as (
    select
      c.relname,
      s.name,
      r.name,
      c.oid
    from
      pg_class c
      inner join mgr.roles r
      on c.relowner = r.oid
      inner join mgr.schemas s
      on c.relnamespace = s.oid
    where relkind in ('r', 'v'))
select
  t.tgname,
  c.name,
  c.schema,
  c.owner,
  pg_get_triggerdef(t.oid, true) as def
from
  relations c
  inner join
  pg_trigger t
  on t.tgrelid = c.oid
  where not t.tgisinternal;

grant select on table mgr.triggers to public;
----------------------------------------------------------------------------------------------------

create function mgr.triggers()
  returns table(z text)
  stable
  security invoker
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  v_name        text    not null := '';
  v_tab_name    text    not null := '';
  v_tab_schema  text    not null := '';
  v_tab_owner   text    not null := '';
  v_defn        text    not null := '';
begin
  z :=
    rpad('name',       40)||
    rpad('tab_name',   10)||
    rpad('tab_schema', 12)||
    rpad('tab_owner',  11)||
    'definition';                                                   return next;

  z :=
    rpad('-', 38, '-')||'  '||
    rpad('-',  8, '-')||'  '||
    rpad('-', 10, '-')||'  '||
    rpad('-',  9, '-')||'  '||
    rpad('-', 30, '-');                                             return next;

  if exists(select 1 from mgr.triggers) then
    for v_name, v_tab_name, v_tab_schema, v_tab_owner, v_defn in (
      select
        name,
        tab_name,
        tab_schema,
        tab_owner,
        definition
      from mgr.triggers
      order by tab_owner, tab_schema, tab_name, name)
    loop
      /*
        Format the definition over three lines to something like this:

          before insert or delete or update
          for each statement
          execute function
          s.generic_trg()

        Notice that "<schema>.<table>" is stripped out because there are
        dedicated columns for "schema" and "table".
      */
      declare
        x constant text not null := '  '||chr(10)||rpad(' ', 73);
        d text not null := ltrim(v_defn, 'CREATE TRIGGER ');
      begin
        d := ltrim(d, quote_ident(v_name));
        d := replace(d, ' '||quote_ident(v_tab_schema)||'.', ' ');
        d := replace(d, ' '||quote_ident(v_tab_name), ' ');

        d := replace(d, ' AFTER ',         'after '    );
        d := replace(d, ' BEFORE ',        'before '   );
        d := replace(d, ' INSERT ',       ' insert '   );
        d := replace(d, ' UPDATE ',       ' update '   );
        d := replace(d, ' DELETE ',       ' delete '   );
        d := replace(d, ' OR ',           ' or '       );
        d := replace(d, ' ON ',           ' '          );

        d := replace(d, ' REFERENCING OLD TABLE AS ',  x||'referencing old table as '  );
        d := replace(d, ' REFERENCING NEW TABLE AS ',  x||'referencing new table as '  );

        d := replace(d, ' FOR EACH ',  x||'for each '  );
        d := replace(d, ' STATEMENT ',    ' statement ');
        d := replace(d, ' ROW ',          ' row '      );
        d := replace(d, ' WHEN ',         ' when '     );

        d := replace(d, ' EXECUTE ',   x||'execute '   );
        d := replace(d, ' FUNCTION ',     ' function ' );
        d := replace(d, ' PROCEDURE ',    ' procedure ');
        d := d||chr(10);

        z :=
          rpad(v_name,       40)||
          rpad(v_tab_name,   10)||
          rpad(v_tab_schema, 12)||
          rpad(v_tab_owner,  11)||
          d;                                                        return next;
      end;
    end loop;
  end if;
end;
$body$;

grant execute on function mgr.triggers() to public;
----------------------------------------------------------------------------------------------------

/*
  "pg_event_trigger.evtevent" LoV:
    D: trigger is disabled
    A: trigger fires always.
    O: trigger fires in "origin" and "local" modes.
    R: trigger fires in "replica" mode.
*/;
create view mgr.event_triggers(owner, name, event_name, enabled) as
select
  r.name,
  t.evtname,
  t.evtevent,
  case t.evtenabled
    when 'D' then 'disabled'
    when 'A' then 'enabled'
    else          'special (unexpected)'
  end
from
  pg_event_trigger t
  inner join mgr.roles r
  on t.evtowner = r.oid;

grant select on table mgr.event_triggers to public;
----------------------------------------------------------------------------------------------------

create function mgr.schema_objects(local in boolean)
  returns table(z text)
  stable
  security invoker
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  v_owner        text    not null := '';
  v_schema       text    not null := '';
  v_kind         text    not null := '';
  v_name         text    not null := '';
  v_security     text    not null := '';
  v_volatility   text    not null := '';
  v_config       text[];

  z0             text    not null := '';
  prev           text    not null := '';
  first_row      boolean not null := true;

  excluded_schemas constant name[] := (
                                        select array_agg(nspname order by nspname)
                                        from pg_namespace
                                        where nspname ~'pg_'
                                        or    nspname ~'yb_'
                                        and   nspname ='information_schema'
                                      );
  common_schemas   constant name[] := array['mgr'::name, 'extensions'::name]; -- consider changing defn of :schema_objects:" view to include ;extensions'
  local_schemas    constant name[] := (
                                        select array_agg(nspname order by nspname)
                                        from pg_namespace
                                        where not (nspname = any(excluded_schemas) or
                                                   nspname = any(common_schemas))
                                      );

  included_schemas constant name[] := case local
                                        when true then local_schemas
                                        else           common_schemas
                                      end;
begin
  z :=
    rpad('owner',       15)||
    rpad('schema',      19)||
    rpad('kind',        17)||
    rpad('name',        40)||
    rpad('security',    11)||
    rpad('volatility',  13)||
    'settings';                                                       return next;

  z :=
    rpad('-', 12, '-')||'   '||
    rpad('-', 16, '-')||'   '||
    rpad('-', 14, '-')||'   '||
    rpad('-', 37, '-')||'   '||
    rpad('-',  8, '-')||'   '||
    rpad('-', 10, '-')||'   '||
    rpad('-', 36, '-');                                             return next;

  if exists(
    select 1 from mgr.schema_objects where schema = any(included_schemas) and kind not in('index', 'sequence')
    )
  then
    for v_owner, v_schema, v_kind, v_name, v_security, v_volatility, v_config in (
      select
        owner,
        schema,
        kind,
        name,
        case
          when security is null then ''
          else                       security
        end,
        case
          when volatility is null then ''
          else                         volatility
        end,
        settings
      from mgr.schema_objects
      where schema = any(included_schemas)
      and kind not in('index', 'sequence')
      order by schema, kind, name)
    loop
      z0 :=
        rpad(v_owner,       15)||
        rpad(v_schema,      19)||
        rpad(v_kind,        17)||
        rpad(v_name,        40)||
        rpad(v_security,    11)||
        rpad(v_volatility,  13)||
        case
          when v_config is null then ''
          else                       v_config[1]
        end;

      if (v_schema != prev) and (not first_row) then
        z := '';                                                    return next;
      end if;
      first_row := false;      
      prev      := v_schema;

      z := z0;                                                      return next;
    end loop;
  end if;
end;
$body$;

grant execute on function mgr.schema_objects(boolean) to public;
----------------------------------------------------------------------------------------------------

create view mgr.constraints(c_name, c_kind, c_expr, t_name, t_schema, t_catalog, t_kind) as
with c(conname, contype, expr, schema_object_oid, schema_object_catalog) as (
  select
    conname,
    case contype
      when 'c' then 'check'
      when 'u' then 'unique'
      when 'p' then 'primary-key'
    end,
    pg_get_expr(conbin, conrelid),
    case contypid
      when 0 then conrelid
      else        contypid
    end,
    case contypid
      when 0 then 'pg_class'
      else        'pg_type'
    end
  from pg_constraint)
select
  c.conname,
  c.contype,
  c.expr,
  s.name,
  s.schema,
  s.catalog,
  s.kind
from
  mgr.schema_objects s
  inner join
  c
  on c.schema_object_oid = s.oid and
     c.schema_object_catalog = s.catalog;

grant select on table mgr.constraints to public;
----------------------------------------------------------------------------------------------------

create view mgr.catalog_views_and_tfs(name) as
select
  case
    when kind = 'function' then name::text||'()'
    else                        name::text
  end
from mgr.schema_objects
where schema = 'mgr'
and   (kind = 'view'     and name not in ('catalog_views_and_tfs', 'roles', 'schemas'))
or    (kind = 'function' and name     in ('roles_and_schemas', 'schema_objects', 'triggers'));

grant select on table mgr.catalog_views_and_tfs to public;
----------------------------------------------------------------------------------------------------

/*
  The main value of this function is pedagogical. It fairly closely mimics the
  output from "\sf+". But there are some trivial cosmetic differences.
  It demonstrates the use of some string manipulation functions and array
  operations--espectially "string_to_array()".
*/
create function mgr.subprogram_source(
  p_name      in name,
  s_name      in name    = 'mgr',
  format_args in boolean = true)
  returns table(z text)
  security invoker
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  p_oid  oid;
  source text;
begin
  select p.oid, p.prosrc
  into   p_oid, source
    from
      pg_proc p
      inner join
      pg_namespace n
      on p.pronamespace = n.oid
    where p.prokind       = any(array['p', 'f']::char[])
    and   p.proname::text = p_name
    and   n.nspname       = s_name;

  if p_oid is null or source is null then
    z := 'No such subprogram';                                                          return next;
  else
    declare
      /*
        If the dollar-quote that surrounds the source text is spelled "$-b-o-d-y-$"
        without the dashes, then any occurrence of this spelling WITHIN what's intended
        to be the source text is deteccted as it's closing dollar-quote! This is
        why the text value for "b" is spelled as it is. If it were spelled literally,
        then this would cause all sorts of crazy compilation errors from whatever text
        follows it.
      */
      b       constant text   not null := '$'||'body'||'$';
      func    constant text   not null := '\$'||'function.*\$';
      proc    constant text   not null := '\$'||'procedure.*\$';

      lines   constant text[] not null := string_to_array(source, e'\n');

      header           text   not null := replace(pg_get_functiondef(p_oid), source, '');
      h_lines          text[] not null := '{}'::text[];

      p1               int    not null := 0;
      p2               int    not null := 0;
      args_0           text   not null := '';
      args_1           text   not null := '';

      lb               int    not null := 0;
      ub               int    not null := 0;
    begin
      /*
        The "pg_get_functiondef)" built-in funtion surrounds the subprogram definition with either
        "$-f-u-n-c-t-i-o-n-$" or "$-p-r-o-c-e-d-u-r-e-$" (without the dashes) unless these dollar quote
        spellings are used within the definition. In this case, "pg_get_functiondef()" avoids collision by
        appending an one or more additional character to what it surrounds the definition with to use,
        for example, "$-f-u-n-c-t-i-o-n-x-$" or "$-p-r-o-c-e-d-u-r-e-x-x-$".
      */
      header := regexp_replace(header, func||'[a-z]*\$', b, 'g');
      header := regexp_replace(header, proc||'[a-z]*\$', b, 'g');
      header := replace(header, b||b, b);

      if format_args then
        p1     := position('(' in header) + 1;
        p2     := position(')' in header) - 1;
        args_0 := substr(header, p1, (1 + p2 - p1));
        args_1 := replace(args_0, ', ', ','||e'\n'||'  ');
        header := replace(header, args_0, e'\n'||'  '||args_1);
      end if;

      h_lines := string_to_array(header, e'\n');

      lb := array_lower(h_lines, 1);
      ub := array_upper(h_lines, 1);
      for j in lb..ub loop
         exit when (j = ub and h_lines[ub] = '');
         z := lpad(' ', 3)||'   '||h_lines[j];                                          return next;
      end loop;

      lb := array_lower(lines, 1);
      ub := array_upper(lines, 1);
      for j in lb..ub loop
        if not (j in (lb, ub) and lines[j] = '') then
          z := lpad(j::text, 3)||'   '||lines[j];                                       return next;
         end if;
      end loop;
      z := lpad(' ', 3)||'   '||b||';';                                                 return next;
    end;
  end if;
end;
$body$;

grant execute on function mgr.subprogram_source(name, name, boolean) to public;
