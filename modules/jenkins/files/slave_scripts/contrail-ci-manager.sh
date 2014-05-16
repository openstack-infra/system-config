#!/usr/bin/env bash

set -ex

# Copy slave scripts from the jenkins.opencontrail.org central master location.
rm -rf /usr/local/jenkins/slave_scripts
ssh root@jenkins.opencontrail.org tar zcf - /usr/local/jenkins/slave_scripts | tar -zx -C /

# Run the real script
exec ruby /usr/local/jenkins/slave_scripts/contrail-ci-manager.rb $*
