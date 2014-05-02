#!/usr/bin/env bash

set -ex

# Copy the file from the jenkins.opencontrail.org master
scp root@148.251.110.18:/usr/local/jenkins/slave_scripts/contrail-git-prep.rb /usr/local/jenkins/slave_scripts/contrail-build-job.sh /usr/local/jenkins/slave_scripts/.

# Run the real script
exec ruby /usr/local/jenkins/slave_scripts/contrail-git-prep.rb $*

