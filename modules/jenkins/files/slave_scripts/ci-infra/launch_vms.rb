#!/usr/bin/env ruby

# Launches as many ci-slaves or ci-subslabes desired!

$LOAD_PATH.unshift "/usr/local/jenkins/slave_scripts/",
                   "/usr/local/jenkins/slave_scripts/ci-infra"

require 'util'

at_exit { Vm.clean_all; Process.exit!(Sh.exit_code) }

# trap("EXIT") { Vm.clean_all; exit Sh.exit }
# trap("INT")  { Vm.clean_all; exit Sh.exit }
# trap("KILL") { Vm.clean_all; exit Sh.exit }
# trap("QUIT") { Vm.clean_all; exit Sh.exit }

class Vm
    attr_accessor :vmname, :hostip
    @@options = OpenStruct.new

    def Vm.options; return @@options; end

    @@vms = [ ]
    def Vm.all_vms; @@vms end

    def initialize(vmname, hostip)
        @vmname = vmname
        @hostip = hostip
    end


    def delete
        @thread.kill unless @thread.nil?
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

                vms.push(Vm.new(line.split[1], line.split[0])) \
                    if line =~ /\d+\.\d+\d+\.\d+/
            }
        }
        return vms
    end

    def wait
        puts "Waiting for ever!"
        loop do
            break unless File.file? "/root/contrail_systest_job_wait"
            sleep 10
        end
    end

    def Vm.clean_all
        wait
        @@vms.each { |vm| vm.delete }
    end

    def send_keepalive
        # VMs self-destruct themselves unless we periodically ping.
        @thread = Thread.new {
            kfile = "/root/#{@vmname}-jenkins-keepalive.log"
            loop do begin
                t = Time.now
                # puts "Updating time #{t} to #{@vmname}"
                File.open(kfile, "w") {|fp| t.to_a.each {|i| fp.puts i}}
                Sh.run("scp #{kfile} root@#{@hostip}:#{kfile}", true, 1, 1,false)
                #rescue StandardError, Interrupt, SystemExit
                rescue Exception => e
                    # puts "ERROR: scp #{kfile} root@#{@hostip}:#{kfile} #{e}"
                end
                sleep 2
            end
        }
    end

    def Vm.create_internal(vmname, floatingip, metadata, flavor = 4) # large
        puts "Creating VM #{vmname}"
        net_id = Sh.crun "nova net-list |\grep -w internet | awk '{print $2}'"
        image_id = Sh.crun %{glance image-list |\grep " #{@@options.image} " | awk '{print $2}'}
        cmd = "nova boot --poll --flavor #{flavor} #{metadata} --nic net-id=#{net_id} --image #{image_id} #{vmname}"

        if @@options.dry_run then
            puts cmd
            return
        end
        Sh.crun cmd

        private_ip = nil
        while true do
            if Sh.crun("nova list | \grep -w ACTIVE | \grep #{vmname}") =~
                    /internet=(\d+\.\d+\.\d+\.\d+)/ then
                private_ip = $1
                break
            end
            sleep 3
        end

        if !floatingip.nil? then
            port_id = Sh.crun "neutron port-list | \grep #{private_ip} | awk '{print $2}'"
            floatingip_id = Sh.crun "neutron floatingip-list |\grep #{floatingip} | awk '{print $2}'"
            Sh.crun "neutron floatingip-associate #{floatingip_id} #{port_id}"
        end

        sleep 1
        puts "Created instance #{vmname}"

        return private_ip
    end

    def Vm.create_slaves(count = @@options.count)
        1.upto(count) { |i|
            floatingip = Sh.crun %{neutron floatingip-list | \grep -v " 192\." | \grep -m 1 "10\."  | awk '{print $5}'}

            metadata = "--meta slave-labels=#{@@options.labels} " +
                       "--meta slave-executors=#{@@options.executors} " +
                       "--meta slave-master=localhost"

            Vm.create_internal("#{@@options.name}-#{floatingip}", floatingip, metadata)
        }
    end

    def Vm.create_subslaves(count = @@options.count)
        # Find my floatingip
        floatingip = get_hostip()

        metadata = "--meta slave-master=#{Vm.get_interface_ip}"
        1.upto(count) { |i|
            vmname = "ci-oc-subslave-#{floatingip}-#{i}"
            hostip = Vm.create_internal(vmname, nil, metadata, 5) # xlarge
            vm = Vm.new(vmname, hostip)
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
#{ s = ""; @@vms.each { |vm| s += "#{vm.hostip} #{vm.vmname}\n" }; s }
# launch_vms.rb autogeneration end
EOF
        s = File.open("/etc/hosts", "r") { |fp| fp.read }
        s.gsub!(/# launch_vms.rb autogeneration start.*# launch_vms.rb autogeneration end\n/m, '')
        s += etc_hosts
        File.open("/etc/hosts", "w") { |fp| fp.write(s) }

        # Wait for all VMs to come up.
        @@vms.each { |vm| Sh.run("scp /etc/hosts #{vm.hostip}:/etc/.", false, 100, 5) }
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
