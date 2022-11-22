#!/bin/bash

sudo rm -Rf /etc/ybmt-generated/yb-logs/*

sudo -u postgres yb-ctl start \
  --data_dir /var/lib/yb/yugabyte-data \
  --tserver_flags "flagfile=/etc/ybmt-code/pg-and-yb-config-files/yb-tserver.conf, ysql_suppress_unsupported_error=true, log_dir=/etc/ybmt-generated/yb-logs/" \
  &> /tmp/yb-ctl-start.txt

sudo chmod -R a+r /etc/ybmt-generated/yb-logs

sudo -u postgres yb-ctl --data_dir /var/lib/yb/yugabyte-data status
