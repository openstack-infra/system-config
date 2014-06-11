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

envs = "USER=#{ENV['USER']}"
envs += " WORKSPACE=#{ENV['WORKSPACE']}"
envs += " JOB_NAME=#{ENV['JOB_NAME']}"
envs += " PROJECT=#{ENV['PROJECT']}"

Sh.run "ssh #{Vm.all_vms.first.hostip} \"#{envs} mkdir -p #{ENV['WORKSPACE']}\""

# Wait till slave_auto_run starts in the new subslave vm.
loop do
    count = Sh.rrun %{ssh #{Vm.all_vms.first.hostip} "ps -efww | grep slave_auto_run.rb | grep -v grep | wc -l"}
    break if count == "1"
    sleep 5
end

sleep(10) while true

Sh.run "ssh #{Vm.all_vms.first.hostip} \"#{envs} cd #{ENV['WORKSPACE']} && " +
       "source /etc/contrail_bashrc && #{envs} ruby /usr/local/jenkins/slave_scripts/contrail-git-prep.rb\""
Sh.run "ssh #{Vm.all_vms.first.hostip} \"#{envs} cd #{ENV['WORKSPACE']} && " +
       "source /etc/contrail_bashrc && #{envs} /usr/local/jenkins/slave_scripts/contrail-devstack-job.sh\""
