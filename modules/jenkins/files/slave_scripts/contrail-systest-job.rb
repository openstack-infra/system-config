#!/usr/bin/env ruby

$LOAD_PATH.unshift "/usr/local/jenkins/slave_scripts/",
                   "/usr/local/jenkins/slave_scripts/ci-infra"

require 'util'
require 'launch_vms'

def create
    # Launch 2 ci-subslave VMs
    Vm.create_subslaves(2)
end

def get_dual_topo (vm1, vm2)
    topo =<<EOF
from fabric.api import env

host1 = 'root@#{vm1.hostip}'
host2 = 'root@#{vm2.hostip}'
host_build = 'root@#{vm1.hostip}'
ext_routers = []
router_asn = 64512

env.roledefs = {
    'all': [host1],
    'cfgm': [host1],
    'openstack': [host1],
    'control': [host1],
    'compute': [host2],
    'collector': [host1],
    'webui': [host1],
    'database': [host1],
    'build': [host_build],
}

env.openstack_admin_password = 'c0ntrail123'
env.hostnames = {
    'all': ['#{vm1.vmname}', '#{vm2.vmname}']
}

env.password = 'c0ntrail123'
env.passwords = {
    host1: 'c0ntrail123',
    host2: 'c0ntrail123',
    host_build: 'c0ntrail123',
}

env.ostypes = {
    host1:'ubuntu',
    host1:'ubuntu',
}

env.test_repo_dir='#{ENV['HOME']}/test'
env.mail_from='ci-admin@opencontrail.org'
env.mail_to='ci-admin@opencontrail.org'
# env.interface_rename = True
EOF
    return topo
end

def setup
    image = "/root/contrail-install-packages_1.06-12~havana_all.deb"

    vms = Vm.all_vms
    vms = Vm.init_all if vms.empty?

    vms.each { |vm|
        # Sh.run "scp #{image} root@#{vm.vmname}:."
        # Sh.run "ssh #{vm.vmname} dpkg -i #{image}"
    }

    vm = vms.first
    # Sh.run "ssh #{vm.vmname} /opt/contrail/contrail_packages/setup.sh"

    topo_file = "/root/testbed_dual.py"
    File.open(topo_file, "w") { |fp| fp.write get_dual_topo(vms[0], vms[1]) }
    Sh.run "scp #{topo_file} #{vm.vmname}:/opt/contrail/utils/fabfile/testbeds/testbed.py"
    Sh.run "ssh #{vm.vmname} contrail-fab install_contrail"
    puts "ssh #{vm.vmname} contrail-fab setup_all"
    puts "ssh #{vm.vmname} contrail-fab quick_sanity"
end

def run
    # Sh.run "ssh #{vm.vmname} fab quick_sanity"
    sleep 100000
end

def main
    # create
    setup
    run
end

main
