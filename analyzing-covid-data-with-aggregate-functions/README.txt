Use ysqlsh (or psql with PostgreSQL if you like).

EITHER: create and connect as a brand-new ordinary database user;

OR: connect as a test user that you already have.

NOTE: If you don't use a brand new database user, then you'll run the small risk of losing objects that you care about whose names collide with those that the script creates (because it drops each object before creating it).

Make sure that you have already installed the "tablefunc" extension before starting. The instructions are here:

  https://docs.yugabyte.com/latest/api/ysql/extensions/#tablefunc

Then simply start "0.sql" at the ysqlsh (or psql) prompt. It takes only moments.

You'll get new versions of the reports on the "analysis-results" directory. The names of the versions that are shipped in "covid-data-case-study.zip" are suffixed with "-0" to avoid collision. You can do a pairwise diff (to show no differences) as a sanity check when "0.sql" has finished. (There are no such reference copies for the results from running "synthetic-data.sql" because the "normal_rand()" function produces a different set of pseudorandomly distributed values each time this script is run.)

The files on the "scatter-plots" directory are all created manually starting with "2020-10-21-mask-symptoms.csv" and "synthetic-data.csv" on the "analysis-results" directory. The steps to create the plots are explained in "Avgerage COVID-like symptoms vs average mask-wearing by state scatter plot for 21-Oct-2020", here:

  https://docs.yugabyte.com/preview/api/ysql/exprs/aggregate_functions/covid-data-case-study/analyze-the-covidcast-data/scatter-plot-for-2020-10-21/
