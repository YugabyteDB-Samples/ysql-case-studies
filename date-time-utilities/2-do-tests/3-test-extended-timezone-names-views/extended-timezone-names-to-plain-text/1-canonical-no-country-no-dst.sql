\t on
select rule_off('"canonical_no_country_no_dst" plain text', 'level_3');

select
  name,
  lpad(to_char_interval(utc_offset), 6) as "UTC offset"
from canonical_no_country_no_dst
order by utc_offset, name;
\t off
