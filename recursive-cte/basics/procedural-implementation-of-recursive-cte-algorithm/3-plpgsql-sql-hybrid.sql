create procedure procedural_version(max_c1 in int)
  language plpgsql
as $body$
begin
  -- Emulate the non-recursive term.
  delete from final_results;
  delete from previous_results;
  insert into previous_results(c1, c2) values (0, 1), (0, 2), (0, 3);
  insert into final_results(c1, c2) select c1, c2 from previous_results;

  -- Emulate the recursive term.
  while ((select count(*) from previous_results) > 0) loop
    delete from temp_results;
    insert into temp_results
    select c1 + 1, c2 + 10
    from previous_results
    where c1 < max_c1;

    delete from previous_results;
    insert into previous_results(c1, c2) select c1, c2 from temp_results;
    insert into final_results(c1, c2) select c1, c2 from temp_results;
  end loop;
end;
$body$;

call procedural_version(4);
select c1, c2 from final_results order by c1, c2;
