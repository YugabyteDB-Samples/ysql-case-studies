# LOOK !!!

#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root."
exit 1
fi

# ------------------------------------------------------------------------------------------------------------------------------------------

export YBMT_CONFIG=/media/psf/Home/Documents/Bllewell_Documents/Yugabyte/YB-github-repos/ysql-case-studies/multitenancy/ybmt-config

# Send BOTH stdout (the "echo" blank lines) AND stderr (the reports from dos2unix) to the same file.
source $YBMT_CONFIG/bllewell/for-ybmt-bllewell-sh/d2u-ymbt-config.sh &> /tmp/d2u-ymbt-config.txt

# ------------------------------------------------------------------------------------------------------------------------------------------
# .../ubuntu/for-home-directories/ ==> Home-directories for all relevant users

# ".bashrc"
cp $YBMT_CONFIG/ubuntu/for-home-directories/dot-bashrc-for-parallels.txt \
   /home/parallels/.bashrc

cp $YBMT_CONFIG/ubuntu/for-home-directories/dot-bashrc-for-root.txt \
   /root/.bashrc

cp $YBMT_CONFIG/ubuntu/for-home-directories/dot-bashrc-for-postgres.txt \
   /home/postgres/.bashrc

cp $YBMT_CONFIG/ubuntu/for-home-directories/dot-bashrc-for-clstr-mgr.txt \
   /home/clstr_mgr/.bashrc

# ".pgpass"
cp $YBMT_CONFIG/ubuntu/for-home-directories/dot-pgpass.txt \
   /home/parallels/.pgpass

cp $YBMT_CONFIG/ubuntu/for-home-directories/dot-pgpass.txt \
   /root/.pgpass

cp $YBMT_CONFIG/ubuntu/for-home-directories/dot-pgpass.txt \
   /home/postgres/.pgpass

cp $YBMT_CONFIG/ubuntu/for-home-directories/dot-pgpass.txt \
   /home/clstr_mgr/.pgpass

chown -R parallels  /home/parallels
chown -R root       /root
chown -R postgres   /home/postgres
chown -R clstr_mgr  /home/clstr_mgr

chgrp -R parallels  /home/parallels
chgrp -R root       /root
chgrp -R postgres   /home/postgres
chgrp -R clstr_mgr  /home/clstr_mgr

chmod -R 700        /home/parallels
chmod -R 700        /root
chmod -R 700        /home/postgres
chmod -R 700        /home/clstr_mgr

cp $YBMT_CONFIG/ubuntu/for-home-directories/desktop-background.sh /home/parallels/

chown root  /home/parallels/desktop-background.sh
chgrp root  /home/parallels/desktop-background.sh
chmod 444   /home/parallels/desktop-background.sh

# ------------------------------------------------------------------------------------------------------------------------------------------
#
# psqlrc (Find the location for PG with "pg_config --sysconfdir")
# psqlrc (Find the location for YB with "/usr/bin/yugabyte/postgres/bin/pg_config --sysconfdir")

cp $YBMT_CONFIG/ubuntu/psqlrc-files/psqlrc-pg.txt \
            /etc/postgresql-common/psqlrc

chown root  /etc/postgresql-common/psqlrc
chgrp root  /etc/postgresql-common/psqlrc
chmod 444   /etc/postgresql-common/psqlrc

rm -Rf /usr/bin/yugabyte/postgres/etc
mkdir  /usr/bin/yugabyte/postgres/etc

cp $YBMT_CONFIG/ubuntu/psqlrc-files/psqlrc-yb.txt \
            /usr/bin/yugabyte/postgres/etc/psqlrc

chown root  /usr/bin/yugabyte/postgres/etc
chgrp root  /usr/bin/yugabyte/postgres/etc
chmod 555   /usr/bin/yugabyte/postgres/etc

chown root  /usr/bin/yugabyte/postgres/etc/psqlrc
chgrp root  /usr/bin/yugabyte/postgres/etc/psqlrc
chmod 444   /usr/bin/yugabyte/postgres/etc/psqlrc

# ------------------------------------------------------------------------------------------------------------------------------------------
#
# Generated ybmt logs and scripts
# One-time set-up

# rm -Rf         /etc/ybmt-generated
# mkdir          /etc/ybmt-generated

# mkdir          /etc/ybmt-generated/yb-logs
# mkdir          /etc/ybmt-generated/pg-logs
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
mkdir   /etc/ybmt-code/pg-and-yb-config-files
mkdir   /etc/ybmt-code/pg-and-yb-utils-sh
mkdir   /etc/ybmt-code/bllewell
mkdir   /etc/ybmt-code/bllewell/sh/
mkdir   /etc/ybmt-code/bllewell/sql

chown -R root /etc/ybmt-code
chgrp -R root /etc/ybmt-code
chmod -R 555  /etc/ybmt-code

# ----------------------------
#
# .../pg-and-yb-utils-sh/* ==> /etc/ybmt-code/pg-and-yb-utils-sh/

cp $YBMT_CONFIG/ubuntu/pg-and-yb-utils-sh/* \
               /etc/ybmt-code/pg-and-yb-utils-sh/

chown -R root  /etc/ybmt-code/pg-and-yb-utils-sh/*
chgrp -R root  /etc/ybmt-code/pg-and-yb-utils-sh/*
chmod 555      /etc/ybmt-code/pg-and-yb-utils-sh/*

# ----------------------------
#
# .../pg-and-yb-utils-sh/* ==> /etc/ybmt-code/pg-and-yb-config-files/

cp $YBMT_CONFIG/ubuntu/pg-and-yb-config-files/*.conf \
            /etc/ybmt-code/pg-and-yb-config-files/

chown root  /etc/ybmt-code/pg-and-yb-config-files/*.conf
chgrp root  /etc/ybmt-code/pg-and-yb-config-files/*.conf
chmod 644   /etc/ybmt-code/pg-and-yb-config-files/*.conf
chmod 640   /etc/ybmt-code/pg-and-yb-config-files/pg_hba.conf
chmod 640   /etc/ybmt-code/pg-and-yb-config-files/pg_ident.conf

# ----------------------------
#
# .../bllewell/for-ybmt-bllewell-sh ==> /etc/ybmt-code/bllewell/sh/

cp $YBMT_CONFIG/bllewell/for-ybmt-bllewell-sh/* \
               /etc/ybmt-code/bllewell/sh/

rm /etc/ybmt-code/bllewell/sh/aliases-for-macos.sh

chown -R root  /etc/ybmt-code/bllewell/sh/*
chgrp -R root  /etc/ybmt-code/bllewell/sh/*
chmod -R 555   /etc/ybmt-code/bllewell/sh/*

# ----------------------------

cp -R $YBMT_CONFIG/bllewell/for-ybmt-bllewell-sql/*.sql \
                  /etc/ybmt-code/bllewell/sql

rm /etc/ybmt-code/bllewell/sql/psql-shortcut-help-macos.sql

chown -R root     /etc/ybmt-code/bllewell/sql/
chgrp -R root     /etc/ybmt-code/bllewell/sql/
chmod -R 555      /etc/ybmt-code/bllewell/sql/
