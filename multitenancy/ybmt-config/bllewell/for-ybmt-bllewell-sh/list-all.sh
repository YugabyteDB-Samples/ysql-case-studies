# Perfom unix command on every file (i.e. not directory) in every diriectory
# recursively down from, in including, the current directory.
# Exclude "hidden" files like ".DS_Store".

# List all files except for hidden files (i.e. starting with ".")
find . \( ! -regex '.*/\..*' \) -type f -exec /bin/ls -1  {} \;
