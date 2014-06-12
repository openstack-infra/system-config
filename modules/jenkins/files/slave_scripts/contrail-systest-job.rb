#!/usr/bin/env ruby

$LOAD_PATH.unshift "/usr/local/jenkins/slave_scripts/",
                   "/usr/local/jenkins/slave_scripts/ci-infra"

require 'util'
require 'contrail-git-prep'

def create_vms(count = 1)
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
import subprocess

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
env.http_proxy = subprocess.check_output("\grep http_proxy /etc/contrail_bashrc | awk -F '=' '{print $2}'", shell = True).rstrip()

# env.mail_from='ci-admin@opencontrail.org'
# env.mail_to='ci-admin@opencontrail.org'
# env.interface_rename=False
EOF
    puts topo
    return topo
end

def setup_contrail(image)
    return if image.nil? or !File.file? image

    dest_image = Sh.rrun "basename #{image}"
    puts "setup_contrail: #{image}"
    `mkdir -p #{ENV['WORKSPACE']}`
    @topo_file = "#{ENV['WORKSPACE']}/testbed.py"

    @vms = Vm.all_vms
    @vms = Vm.init_all if @vms.nil? or @vms.empty?
    File.open(@topo_file, "w") { |fp| fp.write get_topo }

    @vms.each { |vm|
#       Sh.run "ssh root@#{vm.vmname} apt-get update"
        Sh.run("scp #{image} root@#{vm.vmname}:#{dest_image}", false, 50, 10)
        Sh.run "ssh #{vm.vmname} dpkg -i #{dest_image}"

        # Apply patch to setup.sh to retain apt.conf proxy settings.
        Sh.run "ssh #{vm.vmname} /opt/contrail/contrail_packages/setup.sh", true
    }

end

def install_contrail
    vm = @vms.first
    Sh.run("scp #{@topo_file} #{vm.vmname}:/opt/contrail/utils/fabfile/testbeds/testbed.py", false, 20, 4)
    Sh.run "ssh #{vm.vmname} /usr/local/jenkins/slave_scripts/ci-infra/contrail_fab install_contrail"
    Sh.run "echo \"perl -ni -e 's/JVM_OPTS -Xss\\d+/JVM_OPTS -Xss512/g; print \\$_;' /etc/cassandra/cassandra-env.sh\" | ssh -t #{vm.vmname} \$(< /dev/fd/0)"

    Sh.run "ssh #{vm.vmname} /usr/local/jenkins/slave_scripts/ci-infra/contrail_fab setup_all" unless @options.fab_tests.nil?

    # Reduce number of nova-api and nova-conductors and fix scheduler for
    # even distribution of instances across all compute nodes.
#   Sh.run "ssh #{vm.vmname} /usr/bin/openstack-config --set /etc/nova/nova.conf conductor workers 2"
#   Sh.run "ssh #{vm.vmname} /usr/bin/openstack-config --set /etc/nova/nova.conf DEFAULT osapi_compute_workers 2"
#   Sh.run "ssh #{vm.vmname} service nova-api restart"
#   Sh.run "ssh #{vm.vmname} service nova-conductor restart"

#   Sh.run "ssh #{vm.vmname} /usr/bin/openstack-config --set /etc/nova/nova.conf DEFAULT ram_weight_multiplier 1.0"
#   Sh.run "ssh #{vm.vmname} /usr/bin/openstack-config --set /etc/nova/nova.conf DEFAULT scheduler_weight_classes nova.scheduler.weights.all_weighers"
#   Sh.run "ssh #{vm.vmname} service nova-scheduler restart"
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
    image = Sh.rrun "ls -1 #{repo}/build/artifacts/contrail-install-packages_*_all.deb"
    puts "Successfully built package #{image}"

    return image
end

def setup_sanity
    vm = @vms.first
    branch = @options.branch
    if branch != "master" then # use venv
        Sh.run("ssh #{vm.vmname} \"(source /opt/contrail/api-venv/bin/activate && source /etc/contrail_bashrc && pip install fixtures testtools testresources selenium pyvirtualdisplay)\"", false, 20, 4)
    else
        Sh.run("ssh #{vm.vmname} \"(source /etc/contrail_bashrc && pip install fixtures testtools testresources selenium pyvirtualdisplay)\"", false, 20, 4)
    end

    Sh.run "ssh #{vm.vmname} rm -rf /root/contrail-test"
    Sh.run "ssh #{vm.vmname} git clone --branch #{branch} git@github.com:juniper/contrail-test.git /root/contrail-test"
end

# Verify that contrail-status shows 'up' for all necessary components.
def verify_contrail
    Sh.run "ssh #{@vms[0].vmname} /usr/bin/openstack-status"
    @vms.each { |vm| Sh.run "ssh #{vm.vmname} /usr/bin/contrail-status" }
end

def run_sanity
    Sh.run("ssh #{@vms.first.vmname} /usr/local/jenkins/slave_scripts/ci-infra/contrail_fab #{@options.fab_tests}", true) unless @options.fab_tests.nil?

    # Copy sanity log files, as the sub-slave VMs will go away.
    Sh.run("scp -r #{@vms.first.vmname}:/root/logs #{ENV['WORKSPACE']}/.", true)

    # Get http hyper links to the logs and report summary files.
    Sh.run("lynx --dump #{ENV['WORKSPACE']}/logs/*/test_report.html", true)

    puts "Test complete, checking for any failures.."

    # Check if any test failed or errored.
    count = Sh.rrun(
        %{lynx --dump #{ENV['WORKSPACE']}/logs/*/test_report.html | } +
        %{\grep Status: | \grep "Fail\\|Error" | wc -l}, true).to_i

    if count != 0 then
        puts "****** run_sanity:ci_sanity FAILED ******"
    else
        puts "****** run_sanity:ci_sanity PASSED ******"
    end
    return count
end

def run_test(image = @options.image)
    create_vms(@options.control_nodes + @options.compute_nodes)
    setup_contrail(image)
    install_contrail
    setup_sanity
    verify_contrail
    Sh.exit(run_sanity)
end

@options = OpenStruct.new
@options.compute_nodes = 1
@options.control_nodes = 1
@options.image = nil
@options.branch = ENV['ZUUL_BRANCH'] || "master"
@options.fab_tests = "run_sanity:ci_sanity"

def parse_options(args = ARGV)
    opt_parser = OptionParser.new { |o|
        o.banner = "Usage: #{$0} [options] [test-targets})"
        o.on("-c", "--compute-nodes [#{@options.compute_nodes}]",
             "Number of compute nodes") { |c|
            @options.compute_nodes = c.to_i
        }
        o.on("-C", "--control-nodes [#{@options.control_nodes}]",
             "Number of control nodes") { |c|
            @options.control_nodes = c.to_i
        }
        o.on("-i", "--image [checkout and build]", "Image to load") { |i|
            @options.image = i
            dest_image = Sh.rrun "basename #{i}"
            Sh.run("sshpass -p c0ntrail123 scp ci-admin@ubuntu-build02:#{i} #{dest_image}")

        }
        o.on("-b", "--branch [#{@options.branch}]", "Branch to use ") { |b|
            @options.branch = b
        }
        o.on("-t", "--test [#{@options.fab_tests}]", "fab test target") { |t|
            @options.fab_tests = t
        }
    }
    opt_parser.parse!(args)
    if !args.empty? then
        @options.fab_tests = ""
        args.each { |t| @options.fab_tests += "#{t} " }
    end
end

if __FILE__ == $0 then
    Util.ci_setup
    parse_options
    if @options.image.nil? then
        ContrailGitPrep.main(false) # Use private repo
        @options.image = build_contrail_packages
    end

    run_test
end
