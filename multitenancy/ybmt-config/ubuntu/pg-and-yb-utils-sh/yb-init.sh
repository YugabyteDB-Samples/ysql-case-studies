#!/bin/bash

sudo -u postgres yb-ctl --data_dir /var/lib/yb/yugabyte-data destroy &> /tmp/yb-ctl-destroy.txt

sudo -u postgres yb-ctl create \
  --data_dir /var/lib/yb/yugabyte-data \
  --tserver_flags "log_dir=/etc/ybmt-generated/yb-logs/" \
  &> /tmp/yb-ctl-create.txt

sudo -u postgres ysqlsh -h localhost -p 5433 -d postgres -U postgres \
  -c " alter role postgres with superuser connection limit -1 login password 'x'; alter database postgres with allow_connections = true connection_limit = -1; "

sudo -u postgres yb-ctl --data_dir /var/lib/yb/yugabyte-data stop

sudo rm -Rf /etc/ybmt-generated/yb-logs/*

sudo -u postgres yb-ctl start \
  --data_dir /var/lib/yb/yugabyte-data \
  --tserver_flags "flagfile=/etc/ybmt-code/pg-and-yb-config-files/yb-tserver.conf, ysql_suppress_unsupported_error=true, log_dir=/etc/ybmt-generated/yb-logs/" \
  &> /tmp/yb-ctl-start.txt

sudo chmod -R a+r /etc/ybmt-generated/yb-logs

sudo -u postgres yb-ctl --data_dir /var/lib/yb/yugabyte-data status

sudo -u postgres ysqlsh -h localhost -p 5433 -d postgres -U postgres \
  -c " select name, setting from pg_settings where category = 'File Locations'; "
