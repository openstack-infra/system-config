#!/bin/bash -ex

# This script is used to compare what got installed
# by pip to a defined list of python packages

# This function takes a list of files that contain
# a lists of python packages and aggregates them
# into a single file that contains the bare list of packages.
# $1 - The list of files containing python packages
# $2 - The destination file (bare list of packages)
function proccess_package_list () {
    IN_FILES=$1
    OUT_FILE=$2
    truncate --size=0 $OUT_FILE
    for FILE in $IN_FILES
    do
        while read line; do
              if [[ "$line" == "" ]] || [[ "$line" == \#* ]] || [[ "$line" == \-f* ]]; then
                  continue
              elif [[ "$line" == \-e* ]]; then
                  echo "${line#*=}" >> $OUT_FILE
              elif [[ "$line" == *\>* ]]; then
                  echo "${line%%>*}" >> $OUT_FILE
              elif [[ "$line" == *\=* ]]; then
                  echo "${line%%=*}" >> $OUT_FILE
              elif [[ "$line" == *\<* ]]; then
                  echo "${line%%<*}" >> $OUT_FILE
              else
                  echo "${line%%#*}" >> $OUT_FILE
              fi
        done < $FILE
    done
}

REQUIREMENTS_FILES=$1
ALL_REQUIREMENTS_FILE=$2

# Aggregate package lists into one file (without the version info)
proccess_package_list "$REQUIREMENTS_FILES" $ALL_REQUIREMENTS_FILE

# Show list of pip installed packages
.venv/bin/pip freeze > pip_installed.txt
echo "Pip Installed Packages:"
cat pip_installed.txt

# Save packages installed by pip to a file (without the version info)
proccess_package_list pip_installed.txt pip_installed_bare.txt

# Compare packages installed by pip with the source list of requirements
echo "Diff between pip install and requirements:"
grep -v -f pip_installed_bare.txt $ALL_REQUIREMENTS_FILE > diff_requirements.txt
cat diff_requirements.txt