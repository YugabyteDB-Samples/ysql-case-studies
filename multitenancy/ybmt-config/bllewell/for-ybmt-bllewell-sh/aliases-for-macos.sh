echo
echo
echo '# Must be "root" to execute this:'
echo
echo 'install-customization-files'
echo '  ... source $YBMT_CONFIG/macos/install-on-macos.sh'
echo
echo ----------------------------------------------------------------------------------------------------------------------------------
echo 'PG & YB SHORTCUTS'
echo '--------------------------------------------------------------------------------.'
echo
echo 'pgp ................. psql -h u -p 5432 -d postgres -U postgres'
echo 'pgcm ................ psql -h u -p 5432 -d postgres -U clstr$mgr'
echo 'pg0m ................ psql -h u -p 5432 -d d0       -U d0$mgr'
echo
echo 'u-ok ............... psql -h u -p 5432 -d postgres -U postgres -c "select version() as ..."'
echo
echo 'ly ................. show postgres server processes'
echo
echo 'ybp ................ ysqlsh -h u -p 5433 -d postgres -U postgres'
echo 'ybcm ............... ysqlsh -h u -p 5433 -d postgres -U clstr$mgr'
echo 'yb0m ............... ysqlsh -h u -p 5433 -d d0       -U d0$mgr'
echo
echo ----------------------------------------------------------------------------------------------------------------------------------
echo 'BLLEWELL PRODUCTIVITY'
echo '--------------------------------------------------------------------------------.'
echo
echo 'a .................. Produce this help text.'
echo
echo 'c .................. clear screen'
echo 'c10 ................ clear 10 blank lines'
echo 'ls ................. /bin/ls -1'
echo 'lx ................. /bin/ls -ltra | egrep -v ^d # list only non-directories'
echo 'inet ............... /sbin/ifconfig | grep " broadcast "'
echo
echo 'gy ................. cd to .../Yugabyte/'
echo 'gd ................. cd to .../docs/content/preview/api/ysql/'
echo
echo 'py ................. activate the python3 vitual env (new-order project)'
echo
echo 'ybmt-tree ........... tree /etc/ybmt-code/ ; tree /etc/ybmt-generated'
echo
echo 'list-plain-text ..... recursive "ls" from durrent dir for just *.txt, *sql, etc.'
echo 'list-all ........... recursive "ls" from durrent dir'
echo 'd2u ................ recursive "dos2unix" from durrent dir'
echo 'r .................. source ~/.bash_profile'
echo
