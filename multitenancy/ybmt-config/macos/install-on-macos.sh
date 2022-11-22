# LOOK !!!

#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root."
exit 1
fi

# ------------------------------------------------------------------------------------------------------------------------------------------

export YBMT_CLSTR_MGMT=/Users/Bllewell/Documents/Bllewell_Documents/Yugabyte/YB-github-repos/ysql-case-studies/multitenancy/ybmt-clstr-mgmt
export     YBMT_CONFIG=/Users/Bllewell/Documents/Bllewell_Documents/Yugabyte/YB-github-repos/ysql-case-studies/multitenancy/ybmt-config

# Send BOTH stdout (the "echo" blank lines) AND stderr (the reports from dos2unix) to the same file.
source $YBMT_CONFIG/bllewell/for-ybmt-bllewell-sh/d2u-ymbt-config.sh &>     /tmp/d2u-ymbt-config.txt
source $YBMT_CONFIG/bllewell/for-ybmt-bllewell-sh/d2u-ymbt-clstr-mgmt.sh &> /tmp/d2u-ybmt-clstr-mgmt.txt

# ------------------------------------------------------------------------------------------------------------------------------------------
#
# .../macos/for-home-directories/ ==> Home-directories for all relevant users


cp $YBMT_CONFIG/macos/for-home-directories/dot-bash-profile.txt \
   /Users/Bllewell/.bash_profile

cp $YBMT_CONFIG/macos/for-home-directories/dot-bash-profile.txt \
   /var/root/.bash_profile

chown Bllewell  /Users/Bllewell/.bash_profile
chown root      /var/root/.bash_profile

chgrp staff /Users/Bllewell/.bash_profile
chgrp wheel /var/root/.bash_profile

chmod 555 /Users/Bllewell/.bash_profile
chmod 555 /var/root/.bash_profile

cp $YBMT_CONFIG/macos/for-home-directories/dot-pgpass.txt \
   /Users/Bllewell/.pgpass

cp $YBMT_CONFIG/macos/for-home-directories/dot-pgpass.txt \
   /var/root/.pgpass

chown Bllewell /Users/Bllewell/.pgpass
chown root     /var/root/.pgpass

chgrp staff /Users/Bllewell/.pgpass
chgrp wheel /var/root/.pgpass

chmod 400 /Users/Bllewell/.pgpass
chmod 400 /var/root/.pgpass

# ----------------------------
#
# "psqlrc" files to configure "psql" and "ysqlsh".
# Use "pg_config --sysconfdir" to find the copy-to-destination locations.
# Use "/usr/local/share/yugabyte/postgres/bin/pg_config --sysconfdir" to find the copy-to-destination locations.

rm -Rf /usr/local/Cellar/libpq/15.0/etc
mkdir  /usr/local/Cellar/libpq/15.0/etc
mkdir  /usr/local/Cellar/libpq/15.0/etc/postgresql

cp $YBMT_CONFIG/macos/psqlrc-files/psqlrc-pg.txt \
               /usr/local/Cellar/libpq/15.0/etc/postgresql/psqlrc

chown Bllewell /usr/local/Cellar/libpq/15.0/etc/postgresql/psqlrc
chgrp admin    /usr/local/Cellar/libpq/15.0/etc/postgresql/psqlrc
chmod 400      /usr/local/Cellar/libpq/15.0/etc/postgresql/psqlrc

rm -Rf /usr/local/share/yugabyte/postgres/etc
mkdir  /usr/local/share/yugabyte/postgres/etc

cp $YBMT_CONFIG/macos/psqlrc-files/psqlrc-yb.txt \
            /usr/local/share/yugabyte/postgres/etc/psqlrc

chown root  /usr/local/share/yugabyte/postgres/etc/psqlrc
chgrp wheel /usr/local/share/yugabyte/postgres/etc/psqlrc
chmod 444   /usr/local/share/yugabyte/postgres/etc/psqlrc

# ------------------------------------------------------------------------------------------------------------------------------------------
#
# Generated ybmt scripts
# One-time set-up

# rm -Rf         /etc/ybmt-generated
# mkdir          /etc/ybmt-generated

# mkdir          /etc/ybmt-generated/sql-scripts

# chown root    /etc/ybmt-generated
# chgrp root   /etc/ybmt-generated
# chmod -Rf 777 /etc/ybmt-generated

# Routine hygiene.

rm -Rf /etc/ybmt-generated/sql-scripts/*

# ------------------------------------------------------------------------------------------------------------------------------------------
#
# The remaining files will all be copied to subdirectories under "/etc/ybmt-code/"

rm -Rf  /etc/ybmt-code

mkdir   /etc/ybmt-code
mkdir   /etc/ybmt-code/pg-and-yb-utils-sh
mkdir   /etc/ybmt-code/bllewell
mkdir   /etc/ybmt-code/bllewell/sh/
mkdir   /etc/ybmt-code/bllewell/sql
mkdir   /etc/ybmt-code/clstr-mgmt

chown -R root  /etc/ybmt-code
chgrp -R wheel /etc/ybmt-code
chmod -R 555   /etc/ybmt-code

# ----------------------------
#
# .../bllewell/for-ybmt-bllewell-sh ==> /etc/ybmt-code/bllewell/sh/

cp $YBMT_CONFIG/bllewell/for-ybmt-bllewell-sh/* \
               /etc/ybmt-code/bllewell/sh/

rm /etc/ybmt-code/bllewell/sh/aliases-for-ubuntu.sh

chown -R root  /etc/ybmt-code/bllewell/sh/*
chgrp -R wheel /etc/ybmt-code/bllewell/sh/*
chmod -R 555   /etc/ybmt-code/bllewell/sh/*

# ----------------------------

cp -R $YBMT_CLSTR_MGMT/* \
               /etc/ybmt-code/clstr-mgmt/

chown -R root  /etc/ybmt-code/clstr-mgmt
chgrp -R wheel /etc/ybmt-code/clstr-mgmt
chmod -R 555   /etc/ybmt-code/clstr-mgmt

# ----------------------------

cp -R $YBMT_CONFIG/bllewell/for-ybmt-bllewell-sql/*.sql \
               /etc/ybmt-code/bllewell/sql

rm /etc/ybmt-code/bllewell/sql/psql-shortcut-help-ubuntu.sql

chown -R root  /etc/ybmt-code/bllewell/sql/
chgrp -R wheel /etc/ybmt-code/bllewell/sql/
chmod -R 555   /etc/ybmt-code/bllewell/sql/
