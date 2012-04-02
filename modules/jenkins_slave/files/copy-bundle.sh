#!/bin/bash -xe

# Support jobs, such as nova-docs, which are not yet triggered by gerrit
if [ "x$GERRIT_BRANCH" = "x" ] ; then
  GERRIT_BRANCH=master
fi
mv jenkins_venvs/$GERRIT_BRANCH/.cache.bundle .
rm -fr jenkins_venvs

if [ -f tools/test-requires -a \
     `git diff HEAD^1 tools/test-requires 2>/dev/null | wc -l` -gt 0 -o \
     `git diff HEAD^1 tools/pip-requires 2>/dev/null | wc -l` -gt 0 ]
then
  rm .cache.bundle
fi
