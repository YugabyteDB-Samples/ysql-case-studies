call find_paths('Emily', true);

\t on
select t from list_paths('raw_paths');
\t off

call restrict_to_unq_containing_paths('raw_paths', 'unq_containing_paths');

\t on
select t from list_paths('unq_containing_paths');
\t off
