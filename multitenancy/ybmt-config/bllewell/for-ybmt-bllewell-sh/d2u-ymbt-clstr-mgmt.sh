# Notice that {} means each successive file that's found.

echo
find $YBMT_CLSTR_MGMT -regex ".*\.sql$"  -type f -exec dos2unix {} \;
echo
