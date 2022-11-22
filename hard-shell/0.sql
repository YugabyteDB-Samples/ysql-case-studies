/*
  This set of scripts installs and tests the "hard-shell" demo.
  It is designed to be installed in its own database.
  If you use a dedicated cluster with just one "non-system" database
  then you can use ordinary menonic names for the roles. (These are the only global
  phenomena.) The name of the database isn't significant exacpr that the scripts
  need to mention it when the connect.

  Otherwise, you'll need a self-imposed naming convention. I recomend that you simply
  use a cluster that you've set up as a "YBMT" cluster using the scripts under the
  "multitenancy" dirrectory. (It's a peer to the present "hard-shell" directory in
  the present repo. Doind this will hugely simplify things for you.

  These scripts use the "d2" tenant database. These means that all the roles have names that start
  with "d2$". If you want to use a different database, like "d42", then simply do a global seach-and-replace
  to change "d2" to "d42". There aren't many occurrences. So you can inspect and confirm each replacement
  manually.
*/;

-- Install and QA the application-agnostic infrastructure
\ir 10-cr-roles.sql
\ir 20-install-hard-shell-platform.sql
--------------------------------------------------

-- Install the application-specific functionality
\ir 30-install-data.sql
\ir 40-install-code.sql
\ir 50-install-json-shim.sql
\ir 60-install-api.sql

-- NOT NEEDED IN THE DEPLOYED ENV.
\ir 70-install-qa-code.sql
\ir 80-install-qa-ui-simulation.sql
--------------------------------------------------

-- QA the application-specific functionality

\ir 90-qa-code.sql
\ir 91-qa-client-role-functionality.sql
\ir 92-qa-ui-simulation.sql

\c d2 d2$client
