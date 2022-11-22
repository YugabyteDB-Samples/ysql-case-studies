/*
  From:

    "22. Managing Databases"
    www.postgresql.org/docs/11/managing-databases.html
    
  A superuser can drop any database. Dropping a database removes all objects in it,
  even if they have a different owner. Dropping a database cannot be undone.

  You cannot execute "drop database" while connected to the victim database. You
  must therefore be connected to some other database. When the intended victim is
  the only non-system database in the cluster, you must connect to "template1"
  to drop the victim.

  Notice this error:

    25001: DROP DATABASE cannot be executed from a function

  and "create database cannot be executed inside a transaction block" from the
  "create database" doc.

  So to drop all non-template databases except

    "postgres"
    "system_platform" (present only in a YB cluster)

  we need to use a (temporary) function to create the text of
  a ".sql" script, spool it to a file with "\o", and then execute
  that script with "\i". The last line in the script will be
  "\! rm ..." to delete itself.

  See "Create temporary function" by Tom Lane here:
  https://www.postgresql.org/message-id/15191.1208975632@sss.pgh.pa.us
*/;
--------------------------------------------------------------------------------

/*
  This generates and runs a script that locks all victim databases,
  invokes "01-kill-all-sessions-but-self.sql", and then drops the victims.
*/;

-- Using the default means "all".
call mgr.kill_all_sessions_for_specified_database();

\t on
\x off
select mgr.random_script_filename() as filename
\gset script_
\set quoted_script_filename '\'':script_filename'\''
\o :script_filename
select mgr.drop_all_non_system_databases_script(:quoted_script_filename);
\o
\t off
\i :script_filename
