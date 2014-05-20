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
    image = "/root/contrail-install-packages_1.06-12~havana_all.deb"

    vms = Vm.vms
    vms = Vm.init_all if vms.empty?

    vms.each { |vm|
        Sh.run "scp #{image} root@#{vm.vm_name}:."
        Sh.run "ssh #{vm.vm_name} dpkg -i #{image}"
    }

    vm = vms.first
    puts "ssh #{vm.vm_name} /opt/contrail/util/setup.sh"
    puts "ssh #{vm.vm_name} fab install_images"
    puts "ssh #{vm.vm_name} fab setup_all"
    puts "ssh #{vm.vm_name} fab add_images"
end

def run
    # Sh.run "ssh #{vm.vm_name} fab quick_sanity"
    sleep 100000
end

def main
    # create
    setup
    run
end

main
