# Notice that {} means each successive file that's found.

echo
find $YBMT_CONFIG -regex ".*\.txt$"  -type f -exec dos2unix {} \;
echo
find $YBMT_CONFIG -regex ".*\.sql$"  -type f -exec dos2unix {} \;
echo
find $YBMT_CONFIG -regex ".*\.sh$"   -type f -exec dos2unix {} \;
echo
find $YBMT_CONFIG -regex ".*\.conf$" -type f -exec dos2unix {} \;
echo
find $YBMT_CONFIG -regex ".*\.md$"   -type f -exec dos2unix {} \;
echo
find $YBMT_CONFIG -regex ".*\.py"   -type f -exec dos2unix {} \;
echo
