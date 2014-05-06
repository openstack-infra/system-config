#!/usr/bin/env bash

set -ex
exec ruby /usr/local/jenkins/slave_scripts/contrail-build-job.rb
