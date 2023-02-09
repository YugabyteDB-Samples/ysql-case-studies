drop index if exists bacon.raw_paths_terminal_unq cascade;
call bacon.find_paths('Emily', true);
create unique index raw_paths_terminal_unq on bacon.raw_paths(bacon.terminal(path));

\t on
select t from bacon.list_paths('raw_paths');
\t off

call bacon.restrict_to_unq_containing_paths('raw_paths', 'unq_containing_paths');

\t on
select t from bacon.list_paths('unq_containing_paths');
\t off
