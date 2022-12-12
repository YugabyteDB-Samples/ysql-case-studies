\t on
select t from list_paths('raw_paths');
\t off

select repeat_nr, count(*) as number_of_paths
from raw_paths
group by repeat_nr
order by 1;
