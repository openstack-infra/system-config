#!/usr/bin/env ruby

# Launches as many ci-slaves or ci-subslabes desired!

$LOAD_PATH.unshift "/usr/local/jenkins/slave_scripts/",
                   "/usr/local/jenkins/slave_scripts/ci-infra"

require 'util'

Util.ci_setup

# Vm.options.labels = "devstack-subslave"
# Vm.options.name = "ci-oc-devstack-subslave"
# Vm.create_slaves

# Create a new slave node with floating ip!
Vm.create_subslaves(1)

@vms = Vm.all_vms
@vms = Vm.init_all if @vms.nil? or @vms.empty?

# Wait for the the VM to come up and respond.
# Sh.run("ssh #{@vms.first.hostip} uptime", false, 1000, 10)

envs = "USER=#{ENV['USER']} WORKSPACE=#{ENV['WORKSPACE']}"

Sh.run "ssh #{Vm.all_vms.first.hostip} #{envs} mkdir -p #{ENV['WORKSPACE']}"
Sh.run "ssh #{Vm.all_vms.first.hostip} #{envs} cd #{ENV['WORKSPACE']} && #{envs} " +
       "#{envs} /usr/bin/ci_setup.sh"
Sh.run "ssh #{Vm.all_vms.first.hostip}  #{envs} cd #{ENV['WORKSPACE']} && #{envs} " +
       "ruby /usr/local/jenkins/slave_scripts/contrail-git-prep.rb"
Sh.run "ssh #{Vm.all_vms.first.hostip}  #{envs} cd #{ENV['WORKSPACE']} && #{envs} " +
       "/usr/local/jenkins/slave_scripts/contrail-devstack-job.sh"
