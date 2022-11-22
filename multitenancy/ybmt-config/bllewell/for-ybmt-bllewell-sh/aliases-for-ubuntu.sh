echo
echo
echo '# Must be "root" to execute this:'
echo
echo 'install-customization-files'
echo '  ... source $YBMT_CONFIG/ubuntu/install-on-ubuntu.sh'
echo
echo ----------------------------------------------------------------------------------------------------------------------------------
echo 'PG & YB SHORTCUTS'
echo '--------------------------------------------------------------------------------.'
echo
echo 'refresh-pg-config ... cp *.conf files from "ybmt-code" and bounce'
echo
echo 'pg-init ............. stop PG, ...'
echo '        .............   rm data files, init db, restart, pwd-auth-on, set password...'
echo '        .............   for "postgres" to allow client-side connection just for initial set-up.'
echo 'pg-log .............. tail .../pg-server-log/pg-log.txt'
echo
echo 'pgp ................. psql -h localhost -p 5432 -d postgres -U postgres'
echo 'pgcm ................ psql -h localhost -p 5432 -d postgres -U clstr$mgr'
echo
echo 'ly .................. show postgres server processes'
echo
echo 'yb-init ............. yb-ctl destroy, create, pwd-auth-on, set password, ...'
echo '        .............   for "postgres" to allow client-side connection just for initial set-up.'
echo
echo 'yb-log .............. tail .../yb-server-log/postgresql-*'
echo
echo 'ybp ................. ysqlsh -h localhost -p 5433 -d postgres -U postgres'
echo 'ybcm ................ ysqlsh -h localhost -p 5433 -d postgres -U clstr$mgr'
echo
echo ----------------------------------------------------------------------------------------------------------------------------------
echo 'BLLEWELL PRODUCTIVITY'
echo '--------------------------------------------------------------------------------.'
echo
echo 'a ................... Produce this help text.'
echo
echo 'c ................... clear screen'
echo 'c10 ................. clear 10 blank lines'
echo 'ls .................. /bin/ls -1'
echo 'lx .................. /bin/ls -ltra | egrep -v ^d # list only non-directories'
echo 'inet ................ /sbin/ifconfig | grep " broadcast "'
echo
echo 'gy .................. cd to .../Yugabyte/'
echo 'gd .................. cd to .../docs/content/preview/api/ysql/'
echo
echo 'py .................. activate the python3 vitual env (new-order project)'
echo
echo 'ybmt-tree ........... tree /etc/ybmt-code/ ; tree /etc/ybmt-generated'
echo
echo 'list-plain-text ..... recursive "ls" from durrent dir for just *.txt, *sql, etc.'
echo 'list-all ............ recursive "ls" from durrent dir'
echo 'd2u ................. recursive "dos2unix" from durrent dir'
echo 'r .................... source ~/.bashrc'
echo

