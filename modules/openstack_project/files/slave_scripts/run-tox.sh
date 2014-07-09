#!/bin/bash -x

# If a bundle file is present, call tox with the jenkins version of
# the test environment so it is used.  Otherwise, use the normal
# (non-bundle) test environment.  Also, run pip freeze on the
# resulting environment at the end so that we have a record of exactly
# what packages we ended up testing.
#
# Usage: run-tox.sh VENV
#
# Where VENV is the name of the tox environment to run (specified in the
# project's tox.ini file).

venv=$1
shift
org=$1
shift
project=$1
shift
extra_args="$@"

if [[ -z "$venv" || -z "$org" || -z "$project" ]]
then
  echo "Usage: $? VENV ORG PROJECT"
  echo
  echo "VENV: The tox environment to run (eg 'python27')"
  echo "ORG: The project organization (eg 'stackforge')"
  echo "PROJECT: The project name (eg 'nova')"
  echo "EXTRA_ARGS: Extra arguments to pass to tox (for example, '--notest')"
  exit 1
fi

/usr/local/jenkins/slave_scripts/jenkins-oom-grep.sh pre

sudo /usr/local/jenkins/slave_scripts/jenkins-sudo-grep.sh pre

source /usr/local/jenkins/slave_scripts/select-mirror.sh $org $project

tox -v -e$venv $extra_args
result=$?

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

exit $result
