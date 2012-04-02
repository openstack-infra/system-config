#!/bin/bash -xe

if [ -n "$GERRIT_REFNAME" ]
then
  GERRIT_BRANCH=$GERRIT_REFNAME
fi

# Support jobs, such as nova-docs, which are not yet triggered by gerrit
if [ "x$GERRIT_BRANCH" = "x" ] ; then
  GERRIT_BRANCH=master
fi
mv jenkins_venvs/$GERRIT_BRANCH/venv.tgz .
rm -fr jenkins_venvs
tar xfz venv.tgz
rm venv.tgz
if [ -f .cache.bundle ] ; then
  rm -rf .venv
  virtualenv --no-site-packages .venv
  pip install --upgrade -E .venv file://`pwd`/.cache.bundle
  rm .cache.bundle
else
  perl -MCwd -ple '$CWD=Cwd::abs_path();s,^VIRTUAL_ENV=.*,VIRTUAL_ENV="$CWD/.venv",' -i .venv/bin/activate
# This gets easy-install.pth as well as $PROJECT.pth.  Examples for glance:
# easy-install.pth looks like: /home/jenkins/workspace/glance-venv/.venv/src/keystone
# $PROJECT.pth looks like: /home/jenkins/workspace/glance-venv
  perl -MCwd -ple '$CWD=Cwd::abs_path();s,^/.*/workspace/[^/]+(/.*)$,$CWD$1,' -i .venv/lib/python2.7/site-packages/*.pth
# This is needed for the keystone install for glance
  perl -MCwd -ple '$CWD=Cwd::abs_path();s,^/.*/.venv/src/(.*),$CWD/.venv/src/$1,' -i .venv/lib/python2.7/site-packages/*.egg-link
# This is needed for the keystone install for glance
  perl -MCwd -ple '$CWD=Cwd::abs_path();s,/.*/.venv/src/(.*),$CWD/.venv/src/$1,' -i .venv/bin/*
fi
if [ -f tools/test-requires ] ; then
  TEST_REQUIRES='-r tools/test-requires'
fi

if [ -f tools/test-requires -a \
    `git diff HEAD^1 tools/test-requires 2>/dev/null | wc -l` -gt 0 -o \
    `git diff HEAD^1 tools/pip-requires 2>/dev/null | wc -l` -gt 0 ]
then
  rm -rf .venv
  virtualenv --no-site-packages .venv
  pip -E .venv install --upgrade -r tools/pip-requires $TEST_REQUIRES
fi
