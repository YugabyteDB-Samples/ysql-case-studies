\ir 1-set-up-and-ingest-the-covid-data.sql

select (version() like '%YB%')::text as is_yb
\gset

\if :is_yb
  \o output/yb.txt
\else
  \o output/pg.txt
\endif

\ir 0.sql
\o
