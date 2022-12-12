\t on
select rule_off('"canonical_real_country_no_dst" plain text', 'level_3');

select
  name,
  abbrev,
  to_char_interval(utc_offset) as "UTC offset",
  country_code,
  region_coverage
from canonical_real_country_no_dst
order by utc_offset, name;
\t off
