<<comment

  Do this as ANY user that can do "sudo" (and this includes "root" itself)
  See https://manpages.ubuntu.com/manpages/trusty/man8/pg_createcluster.8.html

comment
# --------------------------------------------------------------------------------------------------
#!/bin/bash

sudo pg_dropcluster --stop 11 main
sudo rm -Rf /etc/ybmt-generated/pg-logs/*

sudo pg_createcluster 11 main \
  -e UTF8 --locale=C --lc-collate=C --lc-ctype=en_US.UTF-8 \
  -d /var/lib/postgresql/11/main \
  > /dev/null

sudo cp /etc/ybmt-code/pg-and-yb-config-files/*.conf \
                    /etc/postgresql/11/main

sudo chown postgres /etc/postgresql/11/main/*.conf
sudo chgrp postgres /etc/postgresql/11/main/*.conf
sudo chmod 644      /etc/postgresql/11/main/*.conf
sudo chmod 640      /etc/postgresql/11/main/pg_hba.conf
sudo chmod 640      /etc/postgresql/11/main/pg_ident.conf

sudo pg_ctlcluster start 11/main

sudo -u postgres psql -c " alter role postgres with superuser connection limit -1 login password 'x'; alter database postgres with allow_connections = true connection_limit = -1; "

sudo -u postgres psql -c " select name, setting from pg_settings where category = 'File Locations'; "
