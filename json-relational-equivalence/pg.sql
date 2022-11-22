\o output-files/pg.txt
\ir 01-create-caption.sql

\t on
select caption('Using PostgreSQL 14.2');
\t off

\ir 00-master-script.sql
\o
