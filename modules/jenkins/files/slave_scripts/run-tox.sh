#!/bin/bash -x

# If a bundle file is present, call tox with the jenkins version of
# the test environment so it is used.  Otherwise, use the normal
# (non-bundle) test environment.  Also, run pip freeze on the
# resulting environment at the end so that we have a record of exactly
# what packages we ended up testing.
#
# Usage: run-tox.sh PYTHONVERSION
#
# Where PYTHONVERSION is the numeric version identifier used as a suffix
# in the tox.ini file.  E.g., "26" or "27" for "py26"/"jenkins26" or
# "py27"/"jenkins27" respectively.

version=$1

if [ -z "$version" ]
then
  echo "The tox environment python version (eg '27') must be the first argument."
  exit 1
fi

venv=py$version

export NOSE_WITH_XUNIT=1
export NOSE_WITH_HTML_OUTPUT=1
export NOSE_HTML_OUT_FILE='nose_results.html'

/usr/local/jenkins/slave_scripts/jenkins-oom-grep.sh pre

sudo /usr/local/jenkins/slave_scripts/jenkins-sudo-grep.sh pre

tox -e$venv
result=$?

echo "Begin pip freeze output from test virtualenv:"
echo "======================================================================"
.tox/$venv/bin/pip freeze
echo "======================================================================"

if [ -f ".testrepository/0" ]
then
    cp .testrepository/0 ./subunit_log.txt
    /usr/local/jenkins/slave_scripts/subunit2html.py ./subunit_log.txt testr_results.html
fi

sudo /usr/local/jenkins/slave_scripts/jenkins-sudo-grep.sh post
sudoresult=$?

if [ $sudoresult -ne "0" ]
then
    echo
    echo "This test has failed because it attempted to execute commands"
    echo "with sudo.  See above for the exact commands used."
    echo
    exit 1
fi

/usr/local/jenkins/slave_scripts/jenkins-oom-grep.sh post
oomresult=$?

if [ $oomresult -ne "0" ]
then
    echo
    echo "This test has failed because it attempted to exceed configured"
    echo "memory limits and was killed prior to completion.  See above"
    echo "for related kernel messages."
    echo
    exit 1
fi

htmlreport=$(find . -name $NOSE_HTML_OUT_FILE)
if [ -f "$htmlreport" ]
then
    passcount=$(grep -c 'tr class=.passClass' $htmlreport)
    if [ $passcount -eq "0" ]
    then
        echo
        echo "Zero tests passed, which probably means there was an error"
        echo "parsing one of the python files, or that some other failure"
        echo "during test setup prevented a sane run."
        echo
        exit 1
    fi
else
    echo
    echo "WARNING: Unable to find $NOST_HTML_OUT_FILE to confirm results!"
    echo
fi

exit $result
