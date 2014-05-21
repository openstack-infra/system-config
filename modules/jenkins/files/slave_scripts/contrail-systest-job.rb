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

@setup_sh_patch=<<EOF
--- a/setup.sh
+++ b/setup.sh
@@ -24,8 +24,14 @@ if [ $? != 0 ]; then
      mv new_sources.list sources.list
 fi
 
-#Allow unauthenticated pacakges to get installed
-echo "APT::Get::AllowUnauthenticated \\"true\\";" > apt.conf
+# Allow unauthenticated pacakges to get installed.
+# Do not over-write apt.conf. Instead just append what is necessary
+# retaining other useful configurations such as http::proxy info.
+apt_auth="APT::Get::AllowUnauthenticated \"true\";"
+grep --quiet "$apt_auth" apt.conf
+if [ "$?" != "0" ]; then
+    echo "$apt_auth" >> apt.conf
+fi
 
 #install local repo preferences from /opt/contrail/ to /etc/apt/
 cp /opt/contrail/contrail_packages/preferences /etc/apt/preferences 
EOF

def setup
    image = "/root/contrail-install-packages_1.06-12~havana_all.deb"
    topo_file = "/root/testbed_dual.py"
    patch_file = "/root/setup_sh_patch.diff"

    vms = Vm.all_vms
    vms = Vm.init_all if vms.empty?
    File.open(patch_file, "w") { |fp| fp.write @setup_sh_patch }

    vms.each { |vm|
        Sh.run "ssh root@#{vm.vmname} apt-get update"
        Sh.run "scp #{image} root@#{vm.vmname}:."
        Sh.run "ssh #{vm.vmname} dpkg -i #{image}"

        # Apply patch to setup.sh to retain apt.conf proxy settings.
        Sh.run "scp #{patch_file} #{vm.vmname}:#{patch_file}"
        Sh.run "ssh #{vm.vmname} patch -p1 -d /opt/contrail/contrail_packages/"+
               " -i #{patch_file}"
    }

    vm = vms.first
    Sh.run "ssh #{vm.vmname} /opt/contrail/contrail_packages/setup.sh"

    File.open(topo_file, "w") { |fp| fp.write get_dual_topo(vms[0], vms[1]) }
    Sh.run "scp #{topo_file} #{vm.vmname}:/opt/contrail/utils/fabfile/testbeds/testbed.py"
    Sh.run "ssh #{vm.vmname} contrail-fab install_contrail"
    Sh.run "ssh #{vm.vmname} perl -ni -e 's/JVM_OPTS \-Xss\d+/JVM_OPTS -Xss256/g; print $_;' /etc/cassandra/cassandra-env.sh"
    Sh.run "ssh #{vm.vmname} contrail-fab setup_all"
    Sh.run "ssh #{vm.vmname} contrail-fab run_sanity"
end

def run
    # Sh.run "ssh #{vm.vmname} fab quick_sanity"
    sleep 100000
end

def cleanup
    Vm.clean_all
    Sh.exit
end

def main
    # create
    setup
    run
    cleanup
end

main
