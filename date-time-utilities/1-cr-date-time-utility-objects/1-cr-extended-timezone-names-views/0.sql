\ir 01-cr-to-char-interval.sql
\ir 02-cr-jan-and-jul-tz-abbrevs-and-offsets.sql
\ir 03-copy-from-tz-database.sql
\ir 04-cr-tz-database-time-zones-extended.sql
\ir 05-cr-extended-timezone-names.sql

/*
  These views:
    "canonical_no_country_no_dst"
    "canonical_real_country_no_dst"
    "canonical_real_country_with_dst"
  assume that that following 'assert' holds.
  It ought, to by construction. See "cr-extended-timezone-names.sql".
*/;
do $body$
declare
  c int not null := 0;
begin
  select count(*) from ext_tz_names.extended_timezone_names
  where not utc_offset in (std_offset, dst_offset)
  into c;
  assert c = 0, 'assert failed';
end;
$body$;

\ir 06-cr-canonical-no-country-no-dst.sql
\ir 07-cr-canonical-real-country-no-dst.sql
\ir 08-cr-canonical-real-country-with-dst.sql
\ir 09-drop-temporary-objects.sql
