#!/usr/bin/env ruby

# Launches as many ci-slaves or ci-subslabes desired!

$LOAD_PATH.unshift "/usr/local/jenkins/slave_scripts/",
                   "/usr/local/jenkins/slave_scripts/ci-infra"

require 'util'

# This class VM supports creation of new VMs in the build cluster. When run in
# stand alone mode, it has useful command line arguments as well.
#
# There are two types of VMs that we launch. 'Slaves' which act as jenkins
# slaves to jenkins.opencontrail.org master. They are typically launched by
# directly running this script from command line. They are assigned floating
# IP address, so that they can directly contact external jenkins master server.
#
# Then there are sub-slaves which scripts use to launch additional VMs such
# as when Sanities are run.
#
# These sub-slaves are run with proxy set to the controlling VM. Thus, all
# http, https, ssl, etc traffic can stil go through sub-slaves even though
# they are assigned any floating IP.
#
# When controler VM exits, we go ahead and cleanup all the sub-slave VMs as
# well. In addition, sub-slaves kill themselves if controller VM does not
# periodically ping (and update a timestamp file)

class Vm
    attr_accessor :vmname, :short_name, :hostip
    @@options = OpenStruct.new

    def Vm.options; return @@options; end

    @@vms = [ ]
    def Vm.all_vms; @@vms end

    def initialize(short_name, vmname, hostip)
        @vmname = vmname
        @short_name = short_name
        @hostip = hostip
    end

    # Delete the VM from the cluster
    def delete
        # @thread.kill unless @thread.nil?
        Process.kill("KILL", @keepalive_pid) unless @keepalive_pid.nil?
        Sh.crun "nova delete #{@vmname}"
    end

    # Initialize VMs list from /etc/hosts
    def Vm.init_all
        vms = [ ]
        File.open("/etc/hosts", "r") { |fp|
            start = false
            fp.readlines.each { |line|
                if line =~ /# launch_vms.rb autogeneration start/ then
                    start = true
                    next
                end
                break if line =~ /# launch_vms.rb autogeneration start/
                next unless start

                vms.push(Vm.new(line.split[1], line.split[2], line.split[0])) \
                    if line =~ /\d+\.\d+\d+\.\d+/
            }
        }
        return vms
    end

    def Vm.clean_all
        return if __FILE__ == $0
        @@vms.each { |vm| vm.delete }
    end

    def send_keepalive

        # SubSlave VMs self-destruct themselves unless we periodically ping.
        # @thread = Thread.new
        # Thread causes a deadlock/memory corruption with shell commands
        # So, use a new process instead.
        @parent_pid = Process.pid
        @keepalive_pid = Process.fork
        if @keepalive_pid.nil? then
            # Close file descriptors shared with the parent. This messes up
            # communication channels with the master otherwise.
            $stdin.close; $stdout.close; $stderr.close

            kfile = "/root/#{@vmname}-jenkins-keepalive.log"
            hostip = @hostip
            loop do begin

                # Check if parent is still around. If not, we are done..
                `ps --pid #{@parent_pid}`
                break if $? != 0

                # Check if init has become the parent.
                break if Process.ppid == 1

                t = Time.now
                File.open(kfile, "w") {|fp| t.to_a.each {|i| fp.puts i}}
                `scp #{kfile} root@#{hostip}:#{kfile} &> /dev/null`

                # puts "Updated time #{t} to #{@vmname}"
                # Sh.run("scp #{kfile} root@#{@hostip}:#{kfile}", true, 1, 1,
                #        false)
                # rescue StandardError, Interrupt, SystemExit
                rescue Exception => e
                    # puts "ERROR: scp #{kfile} root@#{@hostip}:#{kfile} #{e}"
                end
                sleep 2
            end
            Kernel.exit!
        end
#       Process.detach(@keepalive_pid)
    end

    def Vm.create_internal(vmname, floatingip, metadata, flavor = 4) # large
        puts "Creating VM #{vmname}"
        net_id, e = Sh.crun "nova net-list |\grep -w internet | awk '{print $2}'"
        image_id, e = Sh.crun %{glance image-list |\grep " #{@@options.image} " | awk '{print $2}'}
        cmd = "nova boot --poll --flavor #{flavor} #{metadata} --nic net-id=#{net_id} --image #{image_id} #{vmname}"

        if @@options.dry_run then
            puts cmd
            return
        end
        Sh.crun cmd

        private_ip = nil
        1.upto(12 * 45) { # at most 45 minutes
            o, e = Sh.crun("nova list | \grep -w ACTIVE | \grep #{vmname}")
            if o =~ /internet=(\d+\.\d+\.\d+\.\d+)/ then
                private_ip = $1
                break
            end
            sleep 5
        }

        if private_ip.nil? then
            puts "nova boot failed for instance #{vmname}"
            Sh.exit(-1)
        end

        if !floatingip.nil? then
            port_id, e = Sh.crun "neutron port-list | \grep #{private_ip} | awk '{print $2}'"
            floatingip_id, e = Sh.crun "neutron floatingip-list |\grep #{floatingip} | awk '{print $2}'"
            Sh.crun "neutron floatingip-associate #{floatingip_id} #{port_id}"
        end

        sleep 1
        puts "Created instance #{vmname}"

        return private_ip
    end

    def Vm.create_slaves(count = @@options.count)
        1.upto(count) { |i|
            floatingip, e = Sh.crun %{neutron floatingip-list | \grep -v " 192\." | \grep -m 1 "10\."  | awk '{print $5}'}

            metadata = "--meta slave-labels=#{@@options.labels} " +
                       "--meta slave-executors=#{@@options.executors} " +
                       "--meta slave-master=localhost"

            vmname = "#{@@options.name}-#{floatingip}"
            vmname.gsub!(/\./, '-')

            short_name = "#{@@options.name}-#{floatingip}"
            short_name.gsub!(/\./, '-')

            hostip = Vm.create_internal(vmname, floatingip, metadata)
            @@vms.push Vm.new(short_name, vmname, hostip)
        }
    end

    def Vm.create_subslaves(count = @@options.count)
        # Find my floatingip
        floatingip = get_hostip()

        metadata = "--meta slave-master=#{Vm.get_interface_ip}"
        1.upto(count) { |i|
            vmname = "ci-oc-subslave-#{floatingip}-#{i}"
            vmname.gsub!(/\./, '-')
            vmname += ".localdomain.com"

            short_name = "ci-oc-subslave-#{floatingip}-#{i}"
            short_name.gsub!(/\./, '-')

            hostip = Vm.create_internal(vmname, nil, metadata, 5) # xlarge
            vm = Vm.new(short_name, vmname, hostip)
            vm.send_keepalive
            @@vms.push vm
        }

        pp @@vms
        setup_etc_hosts

        puts "All ci-sublaves up!"
        pp @@vms
        return @@vms
    end

    def Vm.setup_etc_hosts
        etc_hosts = <<EOF
# launch_vms.rb autogeneration start
#{ s = ""; @@vms.each { |vm| s += "#{vm.hostip} #{vm.short_name} #{vm.vmname}\n" }; s }
# launch_vms.rb autogeneration end
EOF
        s = File.open("/etc/hosts", "r") { |fp| fp.read }
        s.gsub!(/# launch_vms.rb autogeneration start.*# launch_vms.rb autogeneration end\n/m, '')
        s += etc_hosts
        File.open("/etc/hosts", "w") { |fp| fp.write(s) }

        # Wait for all VMs to come up.
        @@vms.each { |vm|
            Sh.run("scp /etc/hosts #{vm.hostip}:/etc/.", false, 100, 5)
        }
    end

    def Vm.setup_image_from_snapshot
        @@base = "/usr/local/jenkins/slave_scripts/"
        Sh.run "nova image-create instance-id #{@@options.image}"
        Sh.run "glance image-download --file #{@@options.image}.qcow2 " +
               "--progress #{@@options.image}"
    end
end

Vm.options.labels = "juniper-tests"
Vm.options.executors = 1
Vm.options.image = "ci-jenkins-slave"
Vm.options.name = "ci-oc-slave"
Vm.options.count = 1
Vm.options.dry_run = false

def parse_options
    opt_parser = OptionParser.new { |o|
        o.banner = "Usage: #{$0} [options] [vms-count(#{Vm.options.count})"
        o.on("-c", "--count [#{Vm.options.count}]",
             "Number of VM Instances") { |c|
            Vm.options.count = c.to_i
        }
        o.on("-l", "--labels [#{Vm.options.labels}]",
             "Jenkins slave node label") { |l|
            Vm.options.labels = l
        }
        o.on("-e", "--executors [#{Vm.options.executors}]",
             "Jenkins job slots count per slave") { |e|
            Vm.options.executors = e
        }
        o.on("-i", "--image [#{Vm.options.image}]",
             "Jenkins slave image ") { |i|
            Vm.options.image = i
        }
        o.on("-n", "--name [#{Vm.options.name}-ipaddr]",
             "VM Instance name prefix") { |n|
            Vm.options.name = n
        }
        o.on("-d", "--[no-]dry-run", "[#{Vm.options.dry_run}]",
             "Just print the nova boot command") { |d|
            Vm.options.dry_run = d
        }
    }
    opt_parser.parse!(ARGV)
    Vm.options.count = ARGV[0].to_i unless ARGV.empty?
end

def main
    parse_options
    Vm.create_slaves
end

main if __FILE__ == $0
