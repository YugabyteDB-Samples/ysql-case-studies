\t on
select caption('11-do-manual-constraint-violation-tests');
\t off

--------------------------------------------------------------------------------------------------------------------------------------------
-- The "book_info" column is declared "not null".
-- Check that it's a "jsonb" object and that it isn't empty.

insert into j_books(book_info)
values
  (' [1, 2] ');

insert into j_books(book_info)
values
  (' {} ');

insert into j_books(book_info)
values
  (' {"isbn": "000-0-00-000000-0", "title": "t", "year": 2010, "authors": [{"family name": "f"}], "genre": "b"} ');

--------------------------------------------------------------------------------------------------------------------------------------------
-- Check that there are no occurrences of « "my key": null » (where "my key" is a known key).
-- Check at the level of the top object and within the "authors" JSON array of objects within that.
insert into j_books(book_info)
values
  (' {"isbn": "000-0-00-000000-0", "title": "t", "year": 2010, "authors": [{"family name": "f"}], "genre": null} ');

insert into j_books(book_info)
values
  (' {"isbn": "000-0-00-000000-0", "year": 2010, "title": "t", "authors": [{"family name": "f", "given name": null}], "genre": "x"} ');

--------------------------------------------------------------------------------------------------------------------------------------------
-- Check for bad key names.
-- Top-level key has bad name.
insert into j_books(book_info)
values
  (' {"isbn": "000-0-00-000000-0", "title": "t", "year": 2010, "authors": [{"family name": "f"}], "bad": "b"} ');

-- "authors key has bad name.
insert into j_books(book_info)
values
  (' {"isbn": "000-0-00-000000-0", "title": "t", "year": 2010, "authors": [{"bad": "x", "family name": "f"}], "genre": "x"} ');

--------------------------------------------------------------------------------------------------------------------------------------------
-- Check that "title" is present.
insert into j_books(book_info)
values
  (' {"isbn": "000-0-00-000000-0", "year": 2010, "authors": [{"family name": "f"}], "genre": "x"} ');

-- Check that "family name" is present.
insert into j_books(book_info)
values
  (' {"isbn": "000-0-00-000000-0", "year": 2010, "title": "t", "authors": [{"family name": "f"}, {"given name": "Sting"}], "genre": "x"} ');

--------------------------------------------------------------------------------------------------------------------------------------------
-- Check that the keys and their datatypes are as expected.
-- "year" has bad data type.
insert into j_books(book_info)
values
  (' {"isbn": "000-0-00-000000-0", "title": "t", "year": "x", "authors": [{"family name": "f", "given name": "g"}], "genre": "x"} ');

--  "authors" key has bad data type.
insert into j_books(book_info)
values
  (' {"isbn": "000-0-00-000000-0", "title": "t", "year": 2010, "authors": {"family name": "f"}, "genre": "x"} ');

-- "family name" has bad data type.
insert into j_books(book_info)
values
  (' {"isbn": "000-0-00-000000-0", "title": "t", "year": 2010, "authors": [{"family name": 0}], "genre": "x"} ');

--------------------------------------------------------------------------------------------------------------------------------------------
-- Check that "isbn" is well-formed.
insert into j_books(book_info)
values
  (' {"isbn": "000-0-x0-000000-0", "title": "t", "year": 2010, "authors": [{"family name": "f"}], "genre": "x"} '); -- has alpha

insert into j_books(book_info)
values
  (' {"isbn": " 000-0-00-000000-0", "title": "t", "year": 2010, "authors": [{"family name": "f"}], "genre": "x"} '); -- space before start

insert into j_books(book_info)
values
  (' {"isbn": "000-0-00-000000-0 ", "title": "t", "year": 2010, "authors": [{"family name": "f"}], "genre": "x"} ');-- space after end

insert into j_books(book_info)
values
  (' {"isbn": "000-00-0-000000-0", "title": "t", "year": 2010, "authors": [{"family name": "f"}], "genre": "x"} '); -- wrong 2nd and 3rd groups

--------------------------------------------------------------------------------------------------------------------------------------------
-- Check that "year" is a positive integer.
insert into j_books(book_info)
values
  (' {"isbn": "000-0-00-000000-0", "title": "t", "year": 4.2, "authors": [{"family name": "f"}], "genre": "x"} ');

-- Check that "year" is a positive integer.
insert into j_books(book_info)
values
  (' {"isbn": "000-0-00-000000-0", "title": "t", "year": 0, "authors": [{"family name": "f"}], "genre": "x"} ');

--------------------------------------------------------------------------------------------------------------------------------------------
-- Check that "authors" array has at least one element.
insert into j_books(book_info)
values
  (' {"isbn": "000-0-00-000000-0", "title": "t", "year": 2010, "authors": [], "genre": "x"} ');

--------------------------------------------------------------------------------------------------------------------------------------------
-- Check that "isbn" is unique.
insert into j_books(book_info)
values
  (' {"isbn": "978-0-14-303809-2", "year": 2010, "title": "t", "authors": [{"family name": "f"}]} ');
