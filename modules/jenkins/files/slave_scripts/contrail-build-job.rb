#!/usr/bin/env ruby

require 'contrail-utils'

pp ENV

# Get the list of files modified by this commit.
DIR.chdir ENV['GERRIT_CONTRAIL_PROJECT_PATH']
pp sh("git diff --name-only origin/#{ENV['ZUUL_BRANCH']}")

# Do pattern match and select appropriate tests.

Dir.chdir "#{ENV['WORKSPACE']}/repo"
# sh "scons -U controller/src/base"
