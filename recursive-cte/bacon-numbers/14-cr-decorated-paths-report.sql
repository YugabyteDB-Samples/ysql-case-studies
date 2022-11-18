create function decorated_paths_report(tab in text, terminal in text default null)
  returns table(t text)
  language plpgsql
as $body$
<<b>>declare
  indent constant int  := 3;
  q      constant text := '''';

  stmt_start constant text := 'select array_agg((path::text) '||
                              'order by cardinality(path), terminal(path), path) '||
                              'from ?';

  where_ constant text := ' where terminal(path) = $1';

  all_terminals_stmt  constant text := replace(stmt_start, '?', tab);
  one_terminal_stmt   constant text := replace(stmt_start, '?', tab)||where_;

  paths text[] not null := '{}';
  p     text   not null := '';
  path  text[] not null := '{}';

  distance         int     not null := -1;
  match            text    not null := '';
  prev_match       text    not null := '';
  movies           text[]  not null := '{}';
  movie            text    not null := '';
  pad              int     not null := 0;
begin
  case terminal is null
    when true then
      execute all_terminals_stmt into paths;
    else
      execute one_terminal_stmt into paths using terminal;
  end case;

  foreach p in array paths loop
    path := p::text[];
    distance := cardinality(path) - 1;
    match := terminal(path);

    -- Rule off before each new match.
    case match = prev_match
      when false then
        t := rpad('-', 50, '-');                                 return next;
    end case;
    prev_match := match;

    pad := 0;
    t := rpad(' ', pad)||path[1];                                return next;
    <<step_loop>>
    for j in 2..cardinality(path) loop
      select e.movies
      into strict b.movies
      from edges e
      where e.node_1 = path[j - 1] and e.node_2 = path[j];

      pad := pad + indent;
      <<movies_loop>>
      foreach movie in array movies loop
        t := rpad(' ', pad)||movie::text;                        return next;
      end loop movies_loop;

      pad := pad + indent;
      t := rpad(' ', pad)||path[j];                              return next;
    end loop step_loop;
  end loop;
  t := rpad('-', 50, '-');                                       return next;
end b;
$body$;

\t on
select t from decorated_paths_report('raw_paths');
select t from decorated_paths_report('raw_paths', 'Helen');
\t off
