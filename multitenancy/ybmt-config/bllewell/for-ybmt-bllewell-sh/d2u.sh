# Notice that {} means each successive file that's found.

echo
find . -regex ".*\.txt$"  -type f -exec dos2unix {} \;
echo
find . -regex ".*\.sql$"  -type f -exec dos2unix {} \;
echo
find . -regex ".*\.sh$"   -type f -exec dos2unix {} \;
echo
find . -regex ".*\.conf$" -type f -exec dos2unix {} \;
echo
find . -regex ".*\.md$"   -type f -exec dos2unix {} \;
echo
find . -regex ".*\.py"   -type f -exec dos2unix {} \;
echo
