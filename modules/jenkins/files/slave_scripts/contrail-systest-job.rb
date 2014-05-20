#!/usr/bin/env ruby

$LOAD_PATH.unshift "/usr/local/jenkins/slave_scripts/",
                   "/usr/local/jenkins/slave_scripts/ci-infra"

require 'util'
require 'launch_vms'

def create
    # Launch 2 ci-subslave VMs
    Vm.create_subslaves(2)
end

def setup
    image = "/root/all_install.deb"
    Vm.vms.each { |vm|
        Sh.run "scp #{image} root@#{vm.vm_name}:#{image}"
        Sh.run "ssh #{vm.vm_name} dpkg -i #{image}"
    }

    Sh.run "ssh #{vm.vm_name} /opt/contrail/util/setup.sh"
    Sh.run "ssh #{vm.vm_name} fab install_images"
    Sh.run "ssh #{vm.vm_name} fab setup_all"
    Sh.run "ssh #{vm.vm_name} fab add_images"
end

def run
    # Sh.run "ssh #{vm.vm_name} fab quick_sanity"
    sleep 100000
end

def main
    create
    # setup
    run
end

main
