#!/usr/bin/env ruby

$LOAD_PATH.unshift "/usr/local/jenkins/slave_scripts/",
                   "/usr/local/jenkins/slave_scripts/ci-infra"

require 'util'
require 'contrail-git-prep'

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
def get_topo(host_build_ip)
    topo =<<EOF
from fabric.api import env
import subprocess

#{get_each_hostip}
host_build = 'root@#{host_build_ip}'
ext_routers = []
router_asn = 64512

env.roledefs = {
    'all': [#{get_all_hosts}],
    'cfgm': [#{@options.cfgm.join(",")}],
    'openstack': [#{@options.openstack.join(",")}],
    'control': [#{@options.control.join(",")}],
    'collector': [#{@options.collector.join(",")}],
    'webui': [#{@options.webui.join(",")}],
    'database': [#{@options.database.join(",")}],
    'compute': [#{@options.compute.join(",")}],
    'build': [host_build],
}

env.openstack_admin_password = 'c0ntrail123'
env.hostnames = { 'all': [#{get_all_host_names}] }
env.password = 'c0ntrail123'
env.passwords = { #{get_each_host_password}, host_build: 'c0ntrail123' }
env.ostypes = { #{get_each_host_ostype} }
env.webui_config = False
env.devstack = False
env.test_retry_factor = 1.0
env.test_delay_factor = 1.0

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

    dest_image, e = Sh.rrun "basename #{image}"
    puts "setup_contrail: #{image}"
    `mkdir -p #{ENV['WORKSPACE']}`
    @topo_file = "#{ENV['WORKSPACE']}/testbed.py"

    @vms = Vm.all_vms
    @vms = Vm.init_all if @vms.nil? or @vms.empty?
    File.open(@topo_file, "w") { |fp| fp.write get_topo(@vms[0].hostip) }

    @vms.each { |vm|
#       Sh.run "ssh root@#{vm.vmname} apt-get update", true
        Sh.run("scp #{image} root@#{vm.vmname}:#{dest_image}", false, 50, 10)
        Sh.run "ssh #{vm.vmname} dpkg -i #{dest_image}"

        # Apply patch to setup.sh to retain apt.conf proxy settings.
        Sh.run "ssh #{vm.vmname} /opt/contrail/contrail_packages/setup.sh", true
    }

end

# Update nova libvirt driver.
def update_nova_libvirt_driver(fab_test)
    return nil if fab_test.nil?

    # Get libvirt type, default to kvm, if support is available
    # TODO Check vmx in the compute nodes.
    libvirt_type_wanted = "kvm"

    # Check if the test demands a particular driver type.
    if fab_test =~ /^(kvm|qemu)_(.*)/ then
        libvirt_type_wanted = $1
        fab_test = $2
    end

    @vms.each { |vm|
        vmx, e = Sh.rrun("ssh #{vm.vmname} \grep -w vmx /proc/cpuinfo | wc -l")
        libvirt_type = libvirt_type_wanted
        libvirt_type = "qemu" if vmx == "0"

        Sh.run "echo \"perl -ni -e 's/libvirt_type=.*/libvirt_type=#{libvirt_type}/g; print \\$_;' /etc/nova/nova-compute.conf\" | ssh -t #{vm.vmname} \$(< /dev/fd/0)", true
        Sh.run "ssh #{vm.vmname} service nova-compute restart", true
    }

    return fab_test
end


def install_contrail
    vm = @vms.first
    Sh.run("scp #{@topo_file} #{vm.vmname}:/opt/contrail/utils/fabfile/testbeds/testbed.py", false, 20, 4)
    Sh.run "ssh #{vm.vmname} /usr/local/jenkins/slave_scripts/ci-infra/contrail_fab install_contrail"
    Sh.run "echo \"perl -ni -e 's/JVM_OPTS -Xss\\d+/JVM_OPTS -Xss512/g; print \\$_;' /etc/cassandra/cassandra-env.sh\" | ssh -t #{vm.vmname} \$(< /dev/fd/0)"

    Sh.run "ssh #{vm.vmname} /usr/local/jenkins/slave_scripts/ci-infra/contrail_fab setup_all" unless @options.fab_tests.empty?

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
    # Fetch build cache
    Sh.run("rm -rf /cs-shared/builder/cache/ubuntu1204")
    Sh.run("sshpass -p c0ntrail123 scp -r ci-admin@ubuntu-build02:/cs-shared/builder/cache/ubuntu1204 /cs-shared/builder/cache/.")

    ENV['BUILD_ONLY'] = "1"
    ENV['SKIP_CREATE_GIT_IDS'] = "1"
    Sh.run "cd #{repo}"
    Sh.run "scons"
#   Sh.run "scons #{repo}/build/third_party/log4cplus"
    Sh.run "rm -rf #{repo}/third_party/euca2ools/.git/shallow"
    Sh.run "cd #{repo}/tools/packaging/build/"
    Sh.run "./packager.py"
    Sh.run "ls -alh #{repo}/build/artifacts/contrail-install-packages_*_all.deb"

    # Return the all-in-one debian package file path.
    image, e = Sh.rrun "ls -1 #{repo}/build/artifacts/contrail-install-packages_*_all.deb"
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

def run_sanity(fab_test)
    return if fab_test.nil?

    # Check if sanities are disabled..
    if @image_built then
        skip_file =
            "/root/ci-test/skip_ci_systest_#{fab_test}_#{@options.branch}"
        o, e = Sh.rrun("ssh jenkins.opencontrail.org ls -1 #{skip_file} 2>/dev/null", true)
        if o =~ /#{skip_file}/ then
            puts "SKIPPED: fab #{fab_test} due to the presence of the file jenkins.opencontrail.org:#{skip_file}"
            return 0
        end
    end

    fab_test = update_nova_libvirt_driver(fab_test)

    o, exit_code = Sh.run("ssh #{@vms.first.vmname} \"TEST_RETRY_FACTOR=10.0 TEST_DELAY_FACTOR=1.2 /usr/local/jenkins/slave_scripts/ci-infra/contrail_fab #{fab_test}\"", true)


    # Copy sanity log files, as the sub-slave VMs will go away.
    Sh.run("scp -r #{@vms.first.vmname}:/root/logs #{ENV['WORKSPACE']}/logs_#{fab_test}", true)

    # Get http hyper links to the logs and report summary files.
    Sh.run("lynx --dump #{ENV['WORKSPACE']}/logs_#{fab_test}/*/test_report.html", true)

    puts "#{fab_test} complete, checking for any failures.."

    # Check if any test failed or errored. Number of matches is consisdered
    # as exit-code, and 0 implies success.
    if exit_code == 0 then
        exit_code, e = Sh.rrun(
            %{lynx --dump #{ENV['WORKSPACE']}/logs_#{fab_test}/*/test_report.html | } +
            %{\grep Status: | \grep "Fail\\|Error" | wc -l}, true).to_i
    end

    if exit_code != 0 then
        puts "****** #{fab_test} FAILED ******"
    else
        puts "****** #{fab_test} PASSED ******"
    end
    return exit_code
end

def run_test(image = @options.image)
    Vm.create_subslaves(@options.nodes)
    setup_contrail(image)
    install_contrail
    setup_sanity
    verify_contrail

    exit_code = 0
    @options.fab_tests.each { |fab_test|
        exit_code = run_sanity(fab_test)
        break if exit_code
        exit_code = run_sanity(fab_test)
    }

    Sh.run("lynx --dump #{ENV['WORKSPACE']}/logs_*/*/test_report.html", true)
    Sh.exit(exit_code)
end

@options = OpenStruct.new
@options.image = nil
@options.branch = ENV['ZUUL_BRANCH'] || "master"
@options.fab_tests = ["run_sanity:ci_sanity", "qemu_run_sanity:ci_svc_sanity"]

@options.nodes = 2
@options.cfgm = ["host1"]
@options.openstack = ["host1"]
@options.control = ["host1"]
@options.collector = ["host1"]
@options.webui = ["host1"]
@options.database = ["host1"]
@options.compute = ["host2"]

def parse_options(args = ARGV)
    compute_set = false
    opt_parser = OptionParser.new { |o|
        o.banner = "Usage: #{$0} [options] [test-targets})"

        o.on("-i", "--image [checkout and build]", "Image to load") { |i|
            dest_image, e = Sh.rrun "basename #{i}"
            @options.image = "#{ENV['WORKSPACE']}/#{dest_image}"
            Sh.run("sshpass -p c0ntrail123 scp ci-admin@ubuntu-build02:#{i} " +
                   "#{ENV['WORKSPACE']}/#{dest_image}")
        }
        o.on("-b", "--branch [#{@options.branch}]", "Branch to use ") { |b|
            @options.branch = b
        }
        o.on("-t", "--test [#{@options.fab_tests}]", Array, "fab test target") { |t|
            @options.fab_tests = t
        }
        o.on("-l", "--libvirt-type [driver]",
             "libvirt driver - kvm in vmx env, qemu otherwise") { |driver|
            @options.libvirt_type = driver
        }
        o.on("-n", "--nodes [#{@options.nodes}]", "Number of nodes") { |n|
            @options.nodes = n.to_i
        }
        o.on("--cfgm host1,..", Array, "List of cfgm nodes " +
             "#{@options.cfgm}") { |list|
            @options.cfgm = list
        }
        o.on("--openstack host1,..", Array, "List of openstack nodes " +
             "#{@options.openstack}") { |list|
            @options.openstack = list
        }
        o.on("--control host1,..", Array, "List of control nodes " +
             "#{@options.control}") { |list|
            @options.control = list
        }
        o.on("--collector host1,..", Array, "List of collector nodes " +
             "#{@options.collector}") { |list|
            @options.collector = list
        }
        o.on("--webui host1,..", Array, "List of webui nodes " +
             "#{@options.webui}") { |list|
            @options.webui = list
        }
        o.on("--database host1,..", Array, "List of database nodes " +
             "#{@options.database}") { |list|
            @options.database = list
        }
        o.on("--compute host2,..", Array, "List of compute nodes " +
             "#{@options.compute}") { |list|
            @options.compute = list
            compute_set = true
        }
    }
    opt_parser.parse!(args)
    if !args.empty? then
        @options.fab_tests = [ ]
        args.each { |t| @options.fab_tests.push t }
    end
    if !compute_set then
        if @options.nodes == 1 then
            @options.compute = [ "host1" ]
        else
            @options.compute = [ ]
            2.upto(@options.nodes) { |i| @options.compute.push("host#{i}") }
        end
    end
end

if __FILE__ == $0 then
    Util.ci_setup
    parse_options
    @image_built = false
    if @options.image.nil? then
        @image_built = true
        ContrailGitPrep.main(false) # Use private repo
        @options.image = build_contrail_packages
    end

    run_test
end
