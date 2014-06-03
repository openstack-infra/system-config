#!/usr/bin/env ruby

$LOAD_PATH.unshift "/usr/local/jenkins/slave_scripts/",
                   "/usr/local/jenkins/slave_scripts/ci-infra"

require 'util'
require 'launch_vms'

Util.ci_setup

def create_vms(count = 1)
    # Launch 2 ci-subslave VMs
    Vm.create_subslaves(count)
end

def get_all_hosts
    return @vms.each_with_index.map { |vm, i| "host#{i+1}" }.join(", ")
end

def get_each_hostip
    return @vms.each_with_index.map { |vm, i| "host#{i+1} = 'root@#{vm.hostip}'" }.join("\n")
end

def get_each_host_password
    return @vms.each_with_index.map { |vm, i| "host#{i+1}: 'c0ntrail123'" }.join(", ")
end

def get_each_host_ostype
    return @vms.each_with_index.map { |vm, i| "host#{i+1}: 'ubuntu'" }.join(", ")
end

def get_all_host_names
    return @vms.each_with_index.map { |vm, i| "'#{vm.vmname}'" }.join(", ")
end


# host1 is always controller node
# Rest are always compute nodes
def get_topo(compute_start = @vms.size > 1 ? 2 : 1)
    computes = "host#{compute_start}"
    (compute_start + 1).upto(@vms.size) { |i| computes += ", host#{i}" }

    topo =<<EOF
from fabric.api import env
import os

#{get_each_hostip}
host_build = 'root@#{@vms[0].hostip}'
ext_routers = []
router_asn = 64512

env.roledefs = {
    'all': [#{get_all_hosts}],
    'cfgm': [host1],
    'openstack': [host1],
    'control': [host1],
    'collector': [host1],
    'webui': [host1],
    'database': [host1],
    'compute': [#{computes}],
    'build': [host_build],
}

env.openstack_admin_password = 'c0ntrail123'
env.hostnames = { 'all': [#{get_all_host_names}] }
env.password = 'c0ntrail123'
env.passwords = { #{get_each_host_password}, host_build: 'c0ntrail123' }
env.ostypes = { #{get_each_host_ostype} }

env.test_repo_dir='#{ENV['HOME']}/contrail-test'
env.mail_from='ci-admin@opencontrail.org'
env.mail_to='ci-admin@opencontrail.org'
env.http_proxy = os.environ.get('http_proxy')
# env.interface_rename=False
EOF
    puts topo
    return topo
end

def setup_contrail
    @image ||= "/root/contrail-install-packages_1.10main-2196~havana_all.deb"
    dest_image = Sh.run "basename #{@image}"
    puts "setup_contrail: #{@image}"
    `mkdir -p #{ENV['WORKSPACE']}`
    @topo_file = "#{ENV['WORKSPACE']}/testbed.py"

    @vms = Vm.all_vms
    @vms = Vm.init_all if @vms.empty?
    File.open(@topo_file, "w") { |fp| fp.write get_topo }

    @vms.each { |vm|
        Sh.run "ssh root@#{vm.vmname} apt-get update"
        Sh.run "scp #{@image} root@#{vm.vmname}:#{dest_image}"
        Sh.run "ssh #{vm.vmname} dpkg -i #{dest_image}"

        # Apply patch to setup.sh to retain apt.conf proxy settings.
        Sh.run "ssh #{vm.vmname} /opt/contrail/contrail_packages/setup.sh"
    }

end

def install_contrail
    vm = @vms.first
    Sh.run "scp #{@topo_file} #{vm.vmname}:/opt/contrail/utils/fabfile/testbeds/testbed.py"
    Sh.run "ssh #{vm.vmname} /usr/local/jenkins/slave_scripts/ci-infra/contrail_fab install_contrail"
    Sh.run "echo \"perl -ni -e 's/JVM_OPTS -Xss\\d+/JVM_OPTS -Xss512/g; print \\$_;' /etc/cassandra/cassandra-env.sh\" | ssh -t #{vm.vmname} \$(< /dev/fd/0)"
    Sh.run "ssh #{vm.vmname} /usr/local/jenkins/slave_scripts/ci-infra/contrail_fab setup_all"
end

def build_contrail_packages(repo = "#{ENV['WORKSPACE']}/repo")
    ENV['BUILD_ONLY'] = "1"
    Sh.run "cd #{repo}"
    Sh.run "scons"
#   Sh.run "scons #{repo}/build/third_party/log4cplus"
    Sh.run "rm -rf #{repo}/third_party/euca2ools/.git/shallow"
    Sh.run "cd #{repo}/tools/packaging/build/"
    Sh.run "./packager.py"
    Sh.run "ls -alh #{repo}/build/artifacts/contrail-install-packages_*_all.deb"

    # Return the all-in-one debian package file path.
    @image = Sh.run "ls -1 #{repo}/build/artifacts/contrail-install-packages_*_all.deb"
    puts "Successfully built package #{@image}"
end

def setup_sanity
    vm = @vms.first
    Sh.run "ssh #{vm.vmname} \"(source /opt/contrail/api-venv/bin/activate && source /etc/bash.bashrc && pip install fixtures testtools testresources selenium pyvirtualdisplay)\""

    branch = ENV['ZUUL_BRANCH'] || "master"
    Sh.run "ssh #{vm.vmname} rm -rf /root/contrail-test"
    Sh.run "ssh #{vm.vmname} git clone --branch #{branch} git@github.com:juniper/contrail-test.git /root/contrail-test"
end

# Verify that contrail-status shows 'up' for all necessary components.
def verify_contrail
    Sh.run "ssh #{@vms[0].vmname} /usr/bin/openstack-status"
    @vms.each { |vm| Sh.run "ssh #{vm.vmname} /usr/bin/contrail-status" }
end

def run_sanity
    Sh.run "ssh #{@vms.first.vmname} /usr/local/jenkins/slave_scripts/ci-infra/contrail_fab run_sanity:quick_sanity"
end

def cleanup
    Vm.clean_all
    Sh.exit
end

def wait
    puts "Waiting for ever!"
    loop do
        break unless File.file? "/root/contrail_systest_job_wait"
        sleep 10
    end
end

def main
    build_contrail_packages
    create_vms(6)
    setup_contrail
    install_contrail
    setup_sanity
    verify_contrail
    run_sanity
    wait
    cleanup
end

main
