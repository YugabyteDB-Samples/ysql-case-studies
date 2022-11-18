drop function if exists timezones_md_table() cascade;
create function timezones_md_table()
  returns table(z text)
  language plpgsql
as $body$
declare
  r constant extended_timezone_names_columns_t not null := extended_timezone_names_columns();
begin
  z :=
                                                     '| '||
    rpad('name',            r.name_pad)            ||'| '||
    rpad('UTC offset',      r.xxx_offset_pad)      ||'| ';          return next;

  z :=
                                                     '| '||
    rpad('----',            r.name_pad)            ||'| '||
    rpad('----------',      r.xxx_offset_pad)      ||'| ';          return next;

  for z in (
    select
                                                                  '| '||
      rpad(name,                         r.name_pad)            ||'| '||
      rpad(to_char_interval(utc_offset), r.xxx_offset_pad)      ||'| '
    from canonical_no_country_no_dst
    order by utc_offset, name)
  loop
                                                                    return next;
  end loop;
end;
$body$;

\t on
select rule_off('"canonical_no_country_no_dst" .md file', 'level_3');
select z from timezones_md_table();
\t off
