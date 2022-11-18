\t on
select rule_off('"canonical_real_country_with_dst" plain text', 'level_3');

select
  name,
  std_abbrev,
  dst_abbrev,
  to_char_interval(std_offset) as "STD offset",
  to_char_interval(dst_offset) as "DST offset",
  country_code,
  region_coverage
from canonical_real_country_with_dst
order by std_offset, name;
\t off
