create view mgr.roles(is_super, name, oid) as
select
  rolsuper,
  rolname::text,
  oid
from pg_roles
where rolname !~ '^pg_'
and   rolname !~ '^yb_'
and   rolname != 'postgres'
and has_database_privilege(rolname, current_database(), 'connect');

grant select on table mgr.roles to public;
----------------------------------------------------------------------------------------------------

create view mgr.schemas(name, owner, oid) as
select
  nspname::text,
  nspowner,
  oid
from pg_namespace
where not (nspname::text = 'information_schema' or nspname::text ~ '^pg' or nspname::text ~ '^yb');

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
  array_agg(s_name order by s_name)
from c
group by rank, is_super, r_name;

grant select on table mgr.roles_and_schemas to public;
----------------------------------------------------------------------------------------------------

create function mgr.granted_roles(r_name in text)
  returns text[]
  stable
  security definer
  set search_path = pg_catalog, pg_temp
  language sql
as $body$
  with c(a) as (
    select array
      (
        select r1.rolname
        from pg_auth_members m inner join pg_roles r1 on m.roleid = r1.oid
        where m.member = r2.oid
        order by r1.rolname
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
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  rol_pad constant int not null := greatest(length('granted roles'), (select max(length(name)) from mgr.roles));
  sch_pad constant int not null := greatest(length('schemas'),       (select max(length(name)) from mgr.schemas));

  v_super    text;
  v_name     text   not null := '';
  v_schemas  text[] not null := '{}';
begin
  z :=
    rpad('super?',                8)||
    rpad('owner',         rol_pad+2)||
    rpad('schemas',       sch_pad+2)||
         'granted roles';                                                               return next;

  z :=
    rpad('-',       6, '-')||'  '||
    rpad('-', rol_pad, '-')||'  '||
    rpad('-', sch_pad, '-')||'  '||
    rpad('-', rol_pad, '-');                                                            return next;

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
      s      text not null := '';
      g      text not null := '';
      grs               constant text[] not null := mgr.granted_roles(v_name);
      schs_cardinality  constant int not null := cardinality(v_schemas);
      grs_cardinality   constant int not null := cardinality(grs);
      max_idx           constant int not null := greatest(schs_cardinality, grs_cardinality);

      schs_1            constant text not null := coalesce(v_schemas[1], '');
      grs_1             constant text not null := coalesce(grs[1],       '');
    begin
      z :=
        rpad(v_super,         8)||
        rpad(v_name,  rol_pad+2)||
        rpad(schs_1,  sch_pad+2)||
             grs_1;                                                                     return next;

      for j in 2..max_idx loop
        declare
          s constant text not null :=
            case
              when j > schs_cardinality then  ''
              else                            v_schemas[j]
            end;
          r constant text not null :=
            case
              when j > grs_cardinality then   ''
              else                            grs[j]
            end;
        begin
          z :=
            rpad('',          8)||
            rpad('',  rol_pad+2)||
            rpad(s,   sch_pad+2)||
                 r;                                                                     return next;
        end;
      end loop;
    end;
    z :=
      rpad('-',       6, '-')||'  '||
      rpad('-', rol_pad, '-')||'  '||
      rpad('-', sch_pad, '-')||'  '||
      rpad('-', rol_pad, '-');                                                          return next;
    end loop;
end;
$body$;

grant execute on function mgr.roles_and_schemas() to public;
----------------------------------------------------------------------------------------------------

create view mgr.schema_objects(oid, owner, schema, name, kind, catalog, security, volatility, settings) as
  with o(oid, owner_oid, schema_oid, name, kind, catalog, security, volatility, settings) as
    (
      select
        oid,
        relowner,
        relnamespace,
        relname,
        case relkind
          when 'r' then 'table'
          when 'v' then 'view'
          when 'i' then 'index'
          when 'S' then 'sequence'
          when 'c' then 'composite-type'
          else          'other'
        end,
        'pg_class',
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
        t.typowner,
        t.typnamespace,
        t.typname,
        'composite-type',
        'pg_type',
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
        typowner,
        typnamespace,
        typname,
        case typtype
          when 'd' then 'domain'
          when 'e' then 'enum'
          else          'other'
        end,
        'pg_type',
        null,
        null,
        null::text[]
      from pg_type t
      where (typtype = 'd' or typtype = 'e')

    union all
      select
        oid,
        proowner,
        pronamespace,
        proname,
        case prokind
          when 'f' then 'function'
          when 'p' then 'procedure'
          else          'other'
        end,
        'pg_proc',
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

    union all
      select
        o.oid,
        o.oprowner,
        o.oprnamespace,
        o.oprname||' [impl. by '||p.proname||']',
        'operator',
        'pg_operator',
        null,
        null,
        null::text[]
      from
        pg_operator o
        inner join
        pg_proc p
        on o.oprcode = p.oid
    )
select
  o.oid,
  r.rolname,
  s.name,
  o.name,
  o.kind,
  catalog,
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

create view mgr.triggers(tab_owner, tab_schema, tab_name, name, definition) as
with
  relations(oid, owner, schema, name)
  as (
    select
      c.oid,
      r.name,
      s.name,
      c.relname
    from
      pg_class c
      inner join mgr.roles r
      on c.relowner = r.oid
      inner join mgr.schemas s
      on c.relnamespace = s.oid
    where relkind in ('r', 'v'))
select
  c.owner,
  c.schema,
  c.name,
  t.tgname,
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
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  own_pad       int  not null := 0;
  sch_pad       int  not null := 0;
  tab_pad       int  not null := 0;
  trg_pad       int  not null := 0;

  v_tab_owner   text not null := '';
  v_tab_schema  text not null := '';
  v_tab_name    text not null := '';
  v_trg_name    text not null := '';
  v_defn        text not null := '';
begin
  select
    greatest(length('tab_owner'),  max(length(tab_owner))),
    greatest(length('tab_schema'), max(length(tab_schema))),
    greatest(length('tab_name'),   max(length(tab_name))),
    greatest(length('name'),       max(length(name)))
  into own_pad, sch_pad, tab_pad, trg_pad
  from mgr.triggers;

  z :=
    rpad('tab_owner',  own_pad+2)||
    rpad('tab_schema', sch_pad+2)||
    rpad('tab_name',   tab_pad+2)||
    rpad('name',       trg_pad+2)||
    'definition';                                                             return next;

  z :=
    rpad('-', own_pad, '-')||'  '||
    rpad('-', sch_pad, '-')||'  '||
    rpad('-', tab_pad, '-')||'  '||
    rpad('-', trg_pad, '-')||'  '||
    rpad('-', 30, '-');                                                       return next;

  if exists(select 1 from mgr.triggers) then
    for v_tab_owner, v_tab_schema, v_tab_name, v_trg_name, v_defn in (
      select
        tab_owner,
        tab_schema,
        tab_name,
        name,
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
        pad constant text not null := rpad('', trg_pad+2)||
                                      rpad('', tab_pad+2)||
                                      rpad('', sch_pad+2)||
                                      rpad('', own_pad+2);
        d text not null := ltrim(v_defn, 'CREATE TRIGGER ');
        d_lines text[] not null := '{}'::text[];
      begin
        d := ltrim(d, quote_ident(v_trg_name));
        d := replace(d, ' '||quote_ident(v_tab_schema)||'.', ' ');
        d := replace(d, quote_ident(v_tab_name)||' ', ' ');

        d := replace(d, ' AFTER ',   'after ');
        d := replace(d, ' BEFORE ',  'before ');
        d := replace(d, ' INSERT ', ' insert ');
        d := replace(d, ' UPDATE ', ' update ');
        d := replace(d, ' DELETE ', ' delete ');
        d := replace(d, ' OR ',     ' or ');
        d := replace(d, ' ON ',     ' ');

        d := replace(d, ' REFERENCING OLD TABLE AS ',  e'\n'||'referencing old table as ');
        d := replace(d, ' REFERENCING NEW TABLE AS ',  e'\n'||'referencing new table as ');

        d := replace(d, ' FOR EACH ',  e'\n'||'for each ');
        d := replace(d, ' STATEMENT ',       ' statement ');
        d := replace(d, ' ROW ',             ' row ');
        d := replace(d, ' WHEN ',            ' when ');

        d := replace(d, ' EXECUTE ',   e'\n'||'execute '   );
        d := replace(d, ' FUNCTION ',        ' function ' );
        d := replace(d, ' PROCEDURE ',       ' procedure ');

        d_lines := string_to_array(d, e'\n');

        for j in array_lower(d_lines, 1)..array_upper(d_lines, 1) loop
          case j
            when 1 then
              z :=
                rpad(v_tab_owner,  own_pad+2)||
                rpad(v_tab_schema, sch_pad+2)||
                rpad(v_tab_name,   tab_pad+2)||
                rpad(v_trg_name,       trg_pad+2)||
                d_lines[1];                                                   return next;
            else
              z := pad||d_lines[j];                                           return next;
          end case;
        end loop;
      end;
      z := '';                                                                return next;
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

create function mgr.schema_objects(local in boolean=true)
  returns table(z text)
  stable
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  own_pad          int not null := 0;
  sch_pad          int not null := 0;
  knd_pad          int not null := 0;
  nam_pad          int not null := 0;
  sec_pad constant int not null := length('security');
  vol_pad constant int not null := length('volatility');

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

  common_schemas   constant name[] := array['client_safe'::name, 'mgr'::name, 'dt_utils'::name];
  local_schemas    constant name[] := (
                                        select array_agg(name)
                                        from mgr.schemas
                                        where name !=  all(common_schemas)
                                      );

  included_schemas constant name[] := case local
                                        when true then local_schemas
                                        else           common_schemas
                                      end;
begin
  select
    greatest(length('owner'),  max(length(owner))),
    greatest(length('schema'), max(length(schema))),
    greatest(length('kind'),   max(length(kind))),
    greatest(length('name'),   max(length(name)))
    into own_pad, sch_pad, knd_pad, nam_pad
    from mgr.schema_objects
    where schema = any(included_schemas)
    and kind not in('index', 'sequence');

  z :=
    rpad('owner',       own_pad+2)||
    rpad('schema',      sch_pad+2)||
    rpad('kind',        knd_pad+2)||
    rpad('name',        nam_pad+2)||
    rpad('security',    sec_pad+2)||
    rpad('volatility',  vol_pad+2)||
    'settings';                                                       return next;

  z :=
    rpad('-', own_pad, '-')||'  '||
    rpad('-', sch_pad, '-')||'  '||
    rpad('-', knd_pad, '-')||'  '||
    rpad('-', nam_pad, '-')||'  '||
    rpad('-', sec_pad, '-')||'  '||
    rpad('-', vol_pad, '-')||'  '||
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
        coalesce(security,   ''),
        coalesce(volatility, ''),
        settings
      from mgr.schema_objects
      where schema = any(included_schemas)
      and kind not in('index', 'sequence')
      order by schema, kind, name)
    loop
      z0 :=
        rpad(v_owner,       own_pad+2)||
        rpad(v_schema,      sch_pad+2)||
        rpad(v_kind,        knd_pad+2)||
        rpad(v_name,        nam_pad+2)||
        rpad(v_security,    sec_pad+2)||
        rpad(v_volatility,  vol_pad+2)||
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

create view mgr.constraints(obj_owner, obj_schema, obj_name, obj_kind, name, kind, expr) as
with c(conname, contype, expr, schema_object_oid, schema_object_catalog) as (
  select
    conname,
    case contype
      when 'c' then 'check'
      when 'u' then 'unique'
      when 'p' then 'primary-key'
      when 'f' then 'foreign-key'
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
  o.owner,
  o.schema,
  o.name,
  o.kind,
  c.conname,
  c.contype,
  c.expr
from
  mgr.schema_objects o
  inner join
  c
  on c.schema_object_oid = o.oid and
     c.schema_object_catalog = o.catalog;

grant select on table mgr.constraints to public;
----------------------------------------------------------------------------------------------------

create function mgr.constraints(local in boolean=true)
  returns table(z text)
  stable
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  own_pad       int  not null := 0;
  sch_pad       int  not null := 0;
  obj_pad       int  not null := 0;
  ok_pad        int  not null := 0;
  cnt_pad       int  not null := 0;
  ck_pad        int  not null := 0;

  v_obj_owner   text not null := '';
  v_obj_schema  text not null := '';
  v_obj_name    text not null := '';
  v_obj_kind    text not null := '';
  v_cnt_name    text not null := '';
  v_cnt_kind    text not null := '';
  v_expr        text not null := '';

  common_schemas   constant name[] := array['mgr'::name, 'dt_utils'::name];
  local_schemas    constant name[] := (
                                        select array_agg(name)
                                        from mgr.schemas
                                        where name !=  all(common_schemas)
                                      );

  included_schemas constant name[] := case local
                                        when true then local_schemas
                                        else           common_schemas
                                      end;

  prev       text    not null := '';
  first_row  boolean not null := true;
begin
  select
    greatest(length('obj_owner'),  max(length(obj_owner))),
    greatest(length('obj_schema'), max(length(obj_schema))),
    greatest(length('obj_name'),   max(length(obj_name))),
    greatest(length('obj_kind'),   max(length(obj_kind))),
    greatest(length('name'),       max(length(name))),
    greatest(length('kind'),       max(length(kind)))
  into own_pad, sch_pad, obj_pad, ok_pad, cnt_pad, ck_pad
  from mgr.constraints;

  z :=
    rpad('obj_owner',  own_pad+2)||
    rpad('obj_schema', sch_pad+2)||
    rpad('obj_name',   obj_pad+2)||
    rpad('obj_kind',   ok_pad+2)||
    rpad('name',       cnt_pad+2)||
    rpad('name',       ck_pad+2)||
    'expression';                                                             return next;

  z :=
    rpad('-', own_pad, '-')||'  '||
    rpad('-', sch_pad, '-')||'  '||
    rpad('-', obj_pad, '-')||'  '||
    rpad('-', ok_pad, '-') ||'  '||
    rpad('-', cnt_pad, '-')||'  '||
    rpad('-', ck_pad, '-') ||'  '||
    rpad('-', 30, '-');                                                       return next;

  if exists(select 1 from mgr.constraints) then
    for v_obj_owner, v_obj_schema, v_obj_name, v_obj_kind, v_cnt_name, v_cnt_kind, v_expr in (
      select
        obj_owner,
        obj_schema,
        obj_name,
        obj_kind,
        name,
        kind,
        coalesce(expr, '')
      from mgr.constraints
      where obj_schema = any(included_schemas)
      order by obj_owner, obj_schema, obj_name, name)
    loop
      if (v_obj_schema != prev) and (not first_row) then
        z := '';                                                              return next;
      end if;
      first_row := false;      
      prev      := v_obj_schema;

      z :=
        rpad(v_obj_owner,  own_pad+2)||
        rpad(v_obj_schema, sch_pad+2)||
        rpad(v_obj_name,   obj_pad+2)||
        rpad(v_obj_kind,   ok_pad+2) ||
        rpad(v_cnt_name,   cnt_pad+2)||
        rpad(v_cnt_kind,   ck_pad+2) ||
        v_expr;                                                               return next;
    end loop;
  end if;
end;
$body$;

grant execute on function mgr.constraints(boolean) to public;
----------------------------------------------------------------------------------------------------
/*
  The main value of this function is pedagogical. It fairly closely mimics the
  output from "\sf+". But there are some trivial cosmetic differences.
  It demonstrates the use of some string manipulation functions and array
  operations--espectially "string_to_array()".
*/
create type mgr.sr_source as (p_oid oid, source text);
create function mgr.subprogram_source(
  p_name      in name,
  s_name      in name    = 'mgr',
  format_args in boolean = true)
  returns table(z text)
  stable
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  s                   mgr.sr_source not null := (0::oid, ''::text);
  subprogram constant mgr.sr_source[] := (
      select       array_agg((p.oid, p.prosrc)::mgr.sr_source)
        from
          pg_proc p
          inner join
          pg_namespace n
          on p.pronamespace = n.oid
        where p.prokind       = any(array['p', 'f']::char[])
        and   p.proname::text = p_name
        and   n.nspname       = s_name
    );
begin
  if subprogram is null or cardinality(subprogram) < 1 then
    z := 'No such subprogram';                                                          return next;
  else
    foreach s in array subprogram loop
      declare
        /*
          If the dollar-quote that surrounds the source text is spelled "$-b-o-d-y-$"
          without the dashes, then any occurrence of this spelling WITHIN what's intended
          to be the source text is detected as its closing dollar-quote! This is
          why the text value for "b" is spelled as it is. If it were spelled literally,
          then this would cause all sorts of crazy compilation errors from whatever text
          follows it.
        */
        b       constant text   not null := '$'||'body'||'$';
        func    constant text   not null := '\$'||'function.*\$';
        proc    constant text   not null := '\$'||'procedure.*\$';

        lines   constant text[] not null := string_to_array(s.source, e'\n');

        header           text   not null := replace(pg_get_functiondef(s.p_oid), s.source, '');
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
           z := lpad(' ', 3)||'   '||h_lines[j];                                        return next;
        end loop;

        lb := array_lower(lines, 1);
        ub := array_upper(lines, 1);
        for j in lb..ub loop
          if not (j in (lb, ub) and lines[j] = '') then
            z := lpad(j::text, 3)||'   '||lines[j];                                     return next;
           end if;
        end loop;
        z := lpad(' ', 3)||'   '||b||';';                                               return next;
      end;
      z := '';                                                                          return next;
    end loop;
  end if;
end;
$body$;

grant execute on function mgr.subprogram_source(name, name, boolean) to public;
--------------------------------------------------------------------------------

create function mgr.dbs_with_comments(exclude_system_dbs in boolean = false)
  returns table(z text)
  stable
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  excluded_dbs constant name[] not null := array['yugabyte'::name, 'system_platform'::name, 'template0'::name, 'template1'::name];
  included_dbs constant name[] not null := case exclude_system_dbs
                                    when false then
                                      (
                                        select array_agg(datname) from pg_database
                                      )
                                    when true then
                                      (
                                        select array_agg(datname) from pg_database
                                        where datname <> all (excluded_dbs)
                                      )
                                  end;
  db_pad       constant int    not null := (select max(length(q.n)) from unnest(included_dbs) as q(n)) + 2;
  rol_pad      constant int    not null := (
                                             select max(length(r.rolname))
                                             from pg_database d inner join pg_roles r on d.datdba = r.oid
                                             where d.datname = any(included_dbs)
                                           ) + 2;
  db_name   name not null := ''::name;
  db_owner  name not null := ''::name;
  comment   text not null := '';

  c_lines text[] not null := '{}'::text[];
begin
  for db_name, db_owner, comment in (
    select d.datname, r.rolname, c.description
    from
      pg_database d
      inner join
      pg_roles r
      on d.datdba = r.oid
      inner join pg_shdescription c
      on d.oid = c.objoid
    where c.classoid = 1262
    and d.datname = any(included_dbs)
    order by d.datistemplate, d.datname)
  loop
    c_lines := string_to_array(comment, e'\n');

    for j in array_lower(c_lines, 1)..array_upper(c_lines, 1) loop
      case j
        when 1 then
          z := rpad(db_name, db_pad)||rpad(db_owner, rol_pad)||c_lines[j];              return next;
        else
          z := rpad('',      db_pad)||rpad('',       rol_pad)||c_lines[j];              return next;
      end case;
    end loop;
  end loop;
end;
$body$;

grant execute on function mgr.dbs_with_comments(boolean) to public;
--------------------------------------------------------------------------------
/*
  As long as a role that is not listed in "mgr.reserved_roles" is created by
  calling "mgr.cr_role()", and never by direct user of the "create role" DDL,
  then all the roles that "mgr.tenant_roles" lists will have well formed names
  that follow the "<database-name>$<role-nickname>" pattern.

  Notice that the ONLY roles with "rolcanlogin" that are able to execute
  "create role" explicitly are "yugabyte" and "clstr$mgr".
*/;
create view mgr.tenant_roles(name, comment) as
with
  roles_with_comments(name, comment) as (
    select r.name, c.description
    from
      mgr.non_reserved_roles r
      inner join pg_shdescription c
      on r.oid = c.objoid
    where  c.classoid = 1260),

  role_with_connect_on_database_pairs(r_name, d_name, comment) as (
      select
        r.name, d.datname, r.comment
      from
        roles_with_comments r
        cross join
        pg_database d
      where has_database_privilege(r.name, d.datname, 'connect')
    )
select r_name, comment
from role_with_connect_on_database_pairs
where  d_name = current_database()           -- Roles that can connect here.

except

select r_name, comment
from role_with_connect_on_database_pairs
where d_name != current_database();         -- Roles that can connect elsewhere and maybe here too

grant select on table mgr.tenant_roles to public;
--------------------------------------------------------------------------------

create type mgr.rolname_and_comment as(r_name name, r_comment text);

create function mgr.roles_with_comments(exclude_mgr_developer_client_and_global_roles in boolean = false)
  returns table(z text)
  stable
  security definer
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
declare
  rol_pad constant int not null := greatest((select max(length(name)) from mgr.roles), length('clstr$developer')) + 2;
  tr mgr.rolname_and_comment not null := (''::name, ''::text)::mgr.rolname_and_comment;
  db constant text not null := current_database()::text||'$';
  excluded_local_roles constant name[] := array[mgr.tenant_role_name('mgr')::name, mgr.tenant_role_name('client')::name];

  local_roles constant mgr.rolname_and_comment[] :=
    case exclude_mgr_developer_client_and_global_roles
      when false then
        (
          select array_agg((r.name, r.comment)::mgr.rolname_and_comment order by r.name)
          from mgr.tenant_roles r
        )
      when true then
        (
          select array_agg((r.name, r.comment)::mgr.rolname_and_comment order by r.name)
          from mgr.tenant_roles r
          where r.name <> all(excluded_local_roles)
        )
    end;

  global_roles constant mgr.rolname_and_comment[] := (
    select array_agg((r.rolname, c.description)::mgr.rolname_and_comment order by r.rolname)
    from
      pg_roles r
      inner join pg_shdescription c
      on r.oid = c.objoid
    where c.classoid = 1260
    and r.rolname in ('yugabyte', 'clstr$mgr', 'clstr$developer'));

  c_lines text[] not null := '{}'::text[];
begin
  if local_roles is not null and cardinality(local_roles) > 0 then
    foreach tr in array local_roles loop
      c_lines := string_to_array(tr.r_comment, e'\n');

      for j in array_lower(c_lines, 1)..array_upper(c_lines, 1) loop
        case j
          when 1 then
            z := rpad(tr.r_name, rol_pad)||c_lines[j];                        return next;
          else
            z := rpad('',        rol_pad)||c_lines[j];                        return next;
        end case;
      end loop;
    end loop;
  end if;

  case exclude_mgr_developer_client_and_global_roles
    when false then
      foreach tr in array global_roles loop
        c_lines := string_to_array(tr.r_comment, e'\n');

        for j in array_lower(c_lines, 1)..array_upper(c_lines, 1) loop
          case j
            when 1 then
              z := rpad(tr.r_name, rol_pad)||c_lines[j];                      return next;
            else
              z := rpad('',        rol_pad)||c_lines[j];                      return next;
          end case;
        end loop;
      end loop;
    when true then
      null;
  end case;
end;
$body$;

grant execute on function mgr.roles_with_comments(boolean) to public;
----------------------------------------------------------------------------------------------------

create view mgr.catalog_views_and_tfs(name, kind) as
select
  case
    when kind = 'function' then name::text||'()'
    else                        name::text
  end,
  kind
from mgr.schema_objects
where schema = 'mgr'
and   (kind = 'view'     and name not in ('catalog_views_and_tfs',
                                          'reserved_roles',
                                          'non_reserved_roles',
                                          'proper_ybmt_roles',
                                          'improper_ybmt_roles',
                                          'roles',
                                          'tenant_roles',
                                          'roles_and_schemas',
                                          'schemas'))
or    (kind = 'function' and name     in ('subprogram_source',
                                          'dbs_with_comments',
                                          'roles_with_comments',
                                          'roles_and_schemas',
                                          'schema_objects',
                                          'constraints',
                                          'triggers'));

grant select on table mgr.catalog_views_and_tfs to public;
