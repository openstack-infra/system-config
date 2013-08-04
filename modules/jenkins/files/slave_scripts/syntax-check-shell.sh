#!/bin/bash -e

function run_syntax {
    for shell_file in $(git ls-files | grep -v .erb$) ; do
        if file $shell_file | grep Bourne >/dev/null ; then
            ksh -n $shell_file
        fi
    done
}

run_syntax
if [ $(run_syntax 2>&1 | wc -l) -gt 0 ] ; then
    echo "Errors found in shell scripts"
    exit 1
fi
