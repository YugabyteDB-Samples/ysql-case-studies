do $body$
begin
  delete from edges;
  delete from cast_members;
  delete from actors;
  delete from movies;

  insert into actors(actor) values
    ('Alfie'),
    ('Chloe'),
    ('Emily'),
    ('Helen'),
    ('James'),
    ('Steve');

  insert into movies(movie) values
    ('As You Like It'),
    ('Coriolanus'),
    ('Hamlet'),
    ('Julius Caesar'),
    ('King Lear'),
    ('Macbeth'),
    ('Measure for Measure'),
    ('Merry Wives of Windsor'),
    ('Othello'),
    ('Romeo and Juliet'),
    ('Taming of the Shrew'),
    ('The Tempest'),
    ('Twelfth Night');

  insert into cast_members(actor, movie) values
 
    ( 'Alfie'  ,  'Hamlet'                 ),
    ( 'Alfie'  ,  'Macbeth'                ),
    ( 'Alfie'  ,  'Measure for Measure'    ),
    ( 'Alfie'  ,  'Taming of the Shrew'    ),

    ( 'Helen'  ,  'The Tempest'            ),
    ( 'Helen'  ,  'Hamlet'                 ),
    ( 'Helen'  ,  'King Lear'              ),
    ( 'Helen'  ,  'Measure for Measure'    ),
    ( 'Helen'  ,  'Romeo and Juliet'       ),
    ( 'Helen'  ,  'Taming of the Shrew'    ),
    ( 'Helen'  ,  'Twelfth Night'          ),

    ( 'Emily'  ,  'As You Like It'         ),
    ( 'Emily'  ,  'Coriolanus'             ),
    ( 'Emily'  ,  'Julius Caesar'          ),
    ( 'Emily'  ,  'Merry Wives of Windsor' ),
    ( 'Emily'  ,  'Othello'                ),

    ( 'Chloe'  ,  'Hamlet'                 ),
    ( 'Chloe'  ,  'Julius Caesar'          ),
    ( 'Chloe'  ,  'Merry Wives of Windsor' ),
    ( 'Chloe'  ,  'Romeo and Juliet'       ),

    ( 'James'  ,  'As You Like It'         ),
    ( 'James'  ,  'Coriolanus'             ),
    ( 'James'  ,  'King Lear'              ),
    ( 'James'  ,  'Othello'                ),
    ( 'James'  ,  'Twelfth Night'          ),

    ( 'Steve'  ,  'The Tempest'            ),
    ( 'Steve'  ,  'King Lear'              ),
    ( 'Steve'  ,  'Macbeth'                );
end;
$body$;

call insert_edges();
