\o output-files/YB.txt
\ir 01-create-caption.sql

\t on
select caption('Using YB-2.13.0.1');
\t off

\ir 00-master-script.sql
\o
