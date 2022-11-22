\echo
\echo
\echo h ................... Show this help text.
\echo
\echo ----------------------------------------------------------------------------------------------------
\echo YBMT SHORTCUTS
\echo ----------------------------------------------------------------------------------------------------
\echo
\echo RC .................. Reset the ybmt cluster to empty (and pristine state).
\echo RD .................. Drop and re-create several "tenant" databases.
\echo DD .................. Drop all "tenant" databases.
\echo
\echo rd .................. Reset the current "tenant" database to pristine.
\echo
\echo lk .................. List the calalog views and table funtions.
\echo ld .................. List all databases with owner and comment.
\echo lr .................. List the two common roles and all the local roles for the current database.
\echo li .................. List all improper YBMT roles for the cluster.
\echo ls .................. List all schemas in the current "tenant" database with their owners.
\echo 'lo .................. List all local schema objects in the current database (from pg_class, pg_type, pg_proc).'
\echo 'co .................. List all common schema objects                        (               "               ).'
\echo lt .................. List all DML triggers on "non-system" tables in the current database.
\echo lc .................. List all DML constraints on "non-system" tables in the current database.
\echo
\echo cr_u0 ............... Drop and re-create user "d0$u0", owning schema "u0", in database "d0".
\echo '                        ...'
\echo cr_u9 ............... Ditto for "u9".
\echo
\echo 'cr_nw ............... Drop and re-create user "northwind", authorized for schema "northwind"'
\echo '                        and install and populate the Northwind sample tables.'
\echo '                        see https://docs.yugabyte.com/latest/sample-data/northwind/'
\echo
\echo cp .................. '\c postgres  postgres'
\echo cm .................. '\c postgres  clstr$mgr'
\echo cm0 ................. '\c d0        d0$mgr'
\echo cc0 ................. '\c d0        d0$client;'
\echo '                        ...'
\echo cm9 ................. '\c d9        d9$mgr'
\echo cc9 ................. '\c d9        d9$client;'

\echo u0 .................. 'set role     d0$u0;'
\echo '                        ...'
\echo u9 .................. 'set role     d0$u9;'
\echo nw .................. 'set role     d0$northwind;'
\echo
\echo ----------------------------------------------------------------------------------------------------
\echo BLLEWELL PRODUCTIVITY
\echo ----------------------------------------------------------------------------------------------------
\echo
\echo w ................... Who and where am I?
\echo c ................... Clear screen by echoing 100 blank lines.
\echo cn................... Clear screen by echoing N   blank lines (currently N=15)
\echo
\echo sw................... set client_min_messages = warning 
\echo se................... set client_min_messages = error
\echo m ................... show client_min_messages
\echo
\echo sd .................. Show data dictionary. (Must be superuser to use it.)
\echo
\echo ms .................. Show metcommand SQL
\echo noms ................ 'Don''t show metcommand SQL'
\echo
\echo t ................... select clock_timestamp().
\echo start_stopwatch ..... start the stopwatch
\echo stopwatch_reading ... read the stopwatch
\echo
\echo d2u ................. Recursive "dos2unix" from durrent dir
\echo q ................... Quit. Same as "\q".
\echo
