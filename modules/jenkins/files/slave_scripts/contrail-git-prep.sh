#!/usr/bin/env bash

set -ex

# Copy slave scripts from the jenkins.opencontrail.org master
rm -rf /usr/local/jenkins/slave_scripts
ssh root@148.251.110.18 tar zcf - /usr/local/jenkins/slave_scripts | tar -zx -C /

# Run the real script
exec ruby /usr/local/jenkins/slave_scripts/contrail-git-prep.rb $*

