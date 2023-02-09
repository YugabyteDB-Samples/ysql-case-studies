\t on
select client_safe.rule_off('05-populate-j-books-table', 'level_3');
\t off
--------------------------------------------------------------------------------
truncate table json.j_books;

insert into json.j_books(book_info)
values
    (' {
         "isbn"    : "978-0-14-303809-2",
         "title"   : "Joy Luck Club",
         "year"    : 2006, 
         "authors" : [
                       {"given name": "Amy", "family name": "Tan"}
                     ],
         "genre"   : "Novel"
       } '),

    (' {
         "isbn"    : "978-0-14-311908-1",
         "title"   : "The Hundred Secret Senses",
         "year":   2010,
         "authors" : [
                       {"given name": "Amy", "family name": "Tan"}
                     ],
         "genre"   : "Novel"
       } '),

    (' {
         "isbn"    : "978-0-13-110362-7",
         "title"   : "C Programming Language",
         "year"    : 1988,
         "authors" : [
                       {"given name": "Brian",  "family name": "Kernighan"},
                       {"given name": "Dennis", "family name": "Ritchie"}
                     ],
         "genre"   : "Programming Languages"
       } '),

    (' {
         "isbn"    : "978-0-14-303841-2",
         "title"   : "Eat, Pray, Love",
         "year"    : 2007,
         "authors" : [
                       {"given name": "Elizabeth", "family name": "Gilbert"}
                     ],
         "genre"   : "Novel"
       } '),

    (' {
         "isbn"    : "978-0-38-533865-3",
         "title"   : "Broken Music",
         "year"    : 2005,
         "authors" : [
                       {"family name": "Sting"}
                     ],
         "genre"   : "Autobiography"
       } '),

    (' {
         "isbn"    : "978-0-38-533987-2",
         "title"   : "Lyrics",
         "year"    : 2007,
         "authors" : [
                       {"family name": "Sting"}
                     ],
         "genre"   : "Autobiography"
       } '),

    (' {
         "isbn"    : "978-0-06-293004-0",
         "title"   : "My Contrary Mary",
         "year"    : 2021,
         "authors" : [
                       {"given name": "Brodi",   "family name": "Ashton"},
                       {"given name": "Cynthia", "family name": "Hand"},
                       {"given name": "Jodi",    "family name": "Meadows"}
                     ],
         "genre"   : "Historical Romance"
       } '),

    (' {
         "isbn"    : "978-0-55-338016-3",
         "title"   : "A Brief History of Time",
         "year"    : 1988,
         "authors" : [
                       {"given name": "Stephen", "family name": "Hawking"}
                     ]
       } ');

select k, jsonb_pretty(book_info) as book_info
from json.j_books
order by k;
