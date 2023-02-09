\t on
select client_safe.rule_off('06-alter-j-books-add-indexes-and-constraints', 'level_3');
\t off
--------------------------------------------------------------------------------

-- FIRST, SOME INDEXES.
-- Unique index on the "isbn" key's "string" value.
create unique index j_books_isbn_unq on json.j_books((book_info->>'isbn'));

-- Non-unique index on the "year" key's "number" value.
create index j_books_year on json.j_books(((book_info->>'year')::int));

-- Non-unique partial index on the "genre" key's "string" value.
create index j_books_genre on json.j_books((book_info->>'genre'))
where book_info->>'genre' is not null;

-- GIN index on the "title" key's "string" value.
create index j_books_title_gin on json.j_books using gin (to_tsvector('english', book_info->>'title'));

-- GIN index on the "authors" key's "string" value.
create index j_books_book_authors_gin on json.j_books using gin((book_info->'authors'));

-- NOW, SOME CONSTRAINTS.
/*
We'll do this at the end:

  alter table json.j_books add constraint j_books_book_info_is_conformant
    check(json.j_books_book_info_is_conformant(book_info));

So first we need to write the function. It's the only way to express some of the rules.
So we may as well express *all* of them in one place.
*/;

create function json.j_books_book_info_is_conformant(book_info in jsonb)
   returns boolean
   immutable
   set search_path = pg_catalog, json, pg_temp
   language plpgsql
as $body$
declare
  check_violation_code constant text not null := '23514';
  check_violation_msg  constant text not null :=
    'row for relation "j_books" violates check constraint "j_books_book_info_is_conformant"';

  object_t constant text not null := 'object';

  -- Describe the expected keys and their JSON datatypes.
  book_info_keys constant key_facts[] not null := top_level_keys();
  author_keys    constant key_facts[] not null := author_keys();

  book_info_type constant text not null := jsonb_typeof(book_info);

  -- Runners.
  key  text not null      := '';
  dt   text not null      := '';
  kd   key_facts not null := ('', '');
begin
  ------------------------------------------------------------------------------
  -- The "book_info" column is declared "not null". Check that "book_info" is a "jsonb" object
  -- and that it isn't empty.
  if book_info_type != object_t then
    raise exception using
      errcode = check_violation_code,
        message = check_violation_msg,
        hint = 'Bad top-level "jsonb" type. Got "'||book_info_type||', should be "'||object_t||'"';

  elsif book_info = '{}'::jsonb then
    raise exception using
      errcode = check_violation_code,
        message = check_violation_msg,
        hint = 'Bad top-level value. Got {}.';

  elsif not no_null_keys(book_info) then
    raise exception using
      errcode = check_violation_code,
        message = check_violation_msg,
        hint = 'book_info has « "some key": null ».';
  end if;

  ------------------------------------------------------------------------------
  -- Check that the top-level keys and their datatypes are as expected
  -- and the all mandatory keys are present.
  declare
    isbn_present     boolean not null := false;
    title_present    boolean not null := false;
    year_present     boolean not null := false;
    authors_present  boolean not null := false;
  begin
    for key in (
      select jsonb_object_keys(book_info))
    loop
      isbn_present    := isbn_present    or key = 'isbn';
      title_present   := title_present   or key = 'title';
      year_present    := year_present    or key = 'year';
      authors_present := authors_present or key = 'authors';
      dt              := jsonb_typeof(book_info->key);
      kd              := (key, dt);

      if not (kd = any(book_info_keys)) then
        raise exception using
          errcode = check_violation_code,
          message = check_violation_msg,
          hint = 'Bad key-name-data-type pair in top-level object: "'||key||'": "'||dt||'"';
      end if;
    end loop;

    if not isbn_present then
      raise exception using
        errcode = check_violation_code,
        message = check_violation_msg,
        hint = 'Bad "book_info" (must have "isbn" key): "'||book_info::text||'"';
    end if;

    if not title_present then
      raise exception using
        errcode = check_violation_code,
        message = check_violation_msg,
        hint = 'Bad "book_info" (must have "title" key): "'||book_info::text||'"';
    end if;

    if not year_present then
      raise exception using
        errcode = check_violation_code,
        message = check_violation_msg,
        hint = 'Bad "book_info" (must have "year" key): "'||book_info::text||'"';
    end if;

    if not authors_present then
      raise exception using
        errcode = check_violation_code,
        message = check_violation_msg,
        hint = 'Bad "book_info" (must have "authors" key): "'||book_info::text||'"';
    end if;
  end;

  ------------------------------------------------------------------------------
  -- Check that "isbn" is well-formed.
  -- We confirmed, above, that the "isbn" key is present with a "string"
  -- data type. So it cannot be null. This assert protects against future
  -- programming errors.
  assert (book_info->>'isbn' is not null), '"isbn" logic error';
                        
  -- PG doc: 9.7. Pattern Matching
  -- https://www.postgresql.org/docs/11/functions-matching.html#FUNCTIONS-POSIX-REGEXP
  -- Example of good "isbn" pattern (alphas prohibited): 978-0-14-303809-2
  declare
    pattern constant text not null := '^[0-9]{3}-[0-9]{1}-[0-9]{2}-[0-9]{6}-[0-9]{1}$';
    isbn    constant text not null := (book_info->>'isbn');
  begin
  -- No need to test « (length(i) = 17) » because the REGEXP itself implies this.
    if not (isbn ~ pattern) then
      raise exception using
        errcode = check_violation_code,
        message = check_violation_msg,
        hint = 'Bad "isbn" pattern, got: "'||isbn||'"';
    end if;
  end;

  ------------------------------------------------------------------------------
  -- We confirmed, above, that the "title" key is present with a "string"
  -- data type. So it cannot be null. This assert protects against future
  -- programming errors.
  assert (book_info->>'title' is not null), '"title" logic error';

  ------------------------------------------------------------------------------
  -- Check that "year" is a positive integer.
  -- We confirmed, above, that the "year" key is present with a "number"
  -- data type. So it cannot be null. This assert protects against future
  -- programming errors.
  assert (book_info->>'year' is not null), '"year" logic error';
  declare
    txt_yr       constant text not null := (book_info->>'year');
    yr                    int not null  := -1;
    bad_integer           boolean not null := false;
  begin
    begin
      -- The typecast to "int" will cause an error of the input "text" does not
      -- represent an integer.
      yr := txt_yr::int;
    exception
      when invalid_text_representation then
        bad_integer := true;
    end;
    if bad_integer then
      raise exception using
        errcode = check_violation_code,
        message = check_violation_msg,
        hint = 'Bad "year": must be an integer';
    end if;

    if yr < 1 then
      raise exception using
        errcode = check_violation_code,
        message = check_violation_msg,
        hint = 'Bad "year": must be a POSITIVE integer';
    end if;
  end;

  ------------------------------------------------------------------------------
  -- "authors"
  -- We confirmed, above, that the "authors" key is present with an "array"
  -- data type. So it cannot be null. This assert protects against future
  -- programming errors.

  assert (book_info->'authors' != 'null'::jsonb), '"authors" logic error';
  declare
    authors constant jsonb not null := book_info->'authors';
  begin
    -- Check that has at least one element. Notice that
    -- the "family name" key is mandatory, but the "given name" key is optional
    -- to allow for e.g. Sting or Prince.
    -- So check that every element has a "family name" key.
    declare
      len constant int not null := jsonb_array_length(authors);
    begin
      if len < 1 then
        raise exception using
          errcode = check_violation_code,
          message = check_violation_msg,
          hint    = 'Bad "authors" (must have at least one element): '||authors::text;
      end if;

      -- Check that the "authors" keys and their datatypes are as expected
      -- and that the one mandator key is present.
      for n in 0..(len - 1) loop
        declare
          author               constant jsonb not null := authors->n;
          family_name_present  boolean not null := false;
        begin
          for key in (
            select jsonb_object_keys(author))
          loop
            family_name_present := family_name_present or key = 'family name';
            dt                  := jsonb_typeof(author->key);
            kd                  := (key, dt);
            declare
              author_keys_ constant key_facts[] not null := author_keys;
            begin
              if not (kd = any(author_keys_)) then
                raise exception using
                  errcode = check_violation_code,
                  message = check_violation_msg,
                  hint = 'Bad key-name-data-type pair in "authors" array: "'||key||'": "'||dt||'"';
              end if;
            end;
          end loop;
          if not family_name_present then
            raise exception using
              errcode = check_violation_code,
              message = check_violation_msg,
              hint = 'Bad "authors" element (must have "family name" key): "'||author::text||'"';
          end if;
        end;
      end loop;
    end;
  end;

  ------------------------------------------------------------------------------
  -- No constraint on "genre" except its data type.
  -- But we _could_ check that the data type name is in a defined LoV.
  ------------------------------------------------------------------------------
  -- Here only if no test failed (i.e. if no exception was raised).
  return true;
end;
$body$;

alter table json.j_books add constraint j_books_book_info_is_conformant
  check(json.j_books_book_info_is_conformant(book_info));
