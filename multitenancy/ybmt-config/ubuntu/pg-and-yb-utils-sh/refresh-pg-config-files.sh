<<comment

  See "pg-init.sh" on this file's directory.
  The "cp", "chown", "chgrp", and "chmod" code is identical.

comment
# --------------------------------------------------------------------------------------------------
#!/bin/bash

sudo cp /etc/ybmt-code/pg-and-yb-config-files/*.conf \
                    /etc/postgresql/11/main

sudo chown postgres /etc/postgresql/11/main/*.conf
sudo chgrp postgres /etc/postgresql/11/main/*.conf
sudo chmod 644      /etc/postgresql/11/main/*.conf
sudo chmod 640      /etc/postgresql/11/main/pg_hba.conf
sudo chmod 640      /etc/postgresql/11/main/pg_ident.conf

sudo -u postgres pg_ctl -D /var/lib/postgresql/11/main reload
