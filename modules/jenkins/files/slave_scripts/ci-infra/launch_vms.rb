#!/usr/bin/env ruby

# Launches as many ci-slaves or ci-subslabes desired!

$LOAD_PATH.unshift "/usr/local/jenkins/slave_scripts/",
                   "/usr/local/jenkins/slave_scripts/ci-infra"

require 'util'

trap("INT")  { Vm.clean_all; exit Sh.exit }
trap("KILL") { Vm.clean_all; exit Sh.exit }
trap("QUIT") { Vm.clean_all; exit Sh.exit }

class Vm
    attr_accessor :vmname, :hostip

    @@base_image = "ci-jenkins-slave"
    @@vms = [ ]
    def all_vms; @@vms end

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

                vms.push(new Vm(line.split[0], line.split[1]))
            }
        }
        return vms
    end

    def Vm.clean_all
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
                Sh.run "scp #{kfile} root@#{@hostip}:#{kfile}", true, 1, 1, false
                #rescue StandardError, Interrupt, SystemExit
                rescue Exception => e
                    # puts "ERROR: scp #{kfile} root@#{@hostip}:#{kfile} #{e}"
                end
                sleep 2
            end
        }
    end

    def Vm.create_internal(vmname, floatingip,
                           slave_master = "--meta slave-master=localhost")
        puts "Creating VM #{vmname}"
        net_id = Sh.crun "nova net-list |\grep -w internet | awk '{print $2}'"
        image_id = Sh.crun %{glance image-list |\grep " #{@@base_image} " | awk '{print $2}'}
        Sh.crun "nova boot --flavor 4 #{slave_master} --nic net-id=#{net_id} --image #{image_id} #{vmname}"

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

    def Vm.create_slaves(count = 1)
        1.upto(count) { |i|
            floatingip = Sh.crun %{neutron floatingip-list | \grep -v " 192\." | \grep -m 1 "10\."  | awk '{print $5}'}
            Vm.create_internal("ci-slave-#{floatingip}", floatingip)
        }
    end

    def Vm.create_subslaves(count = 1)
        # Find my floatingip
        floatingip = get_hostip()
        slave_master = "--meta slave-master=#{Vm.get_interface_ip}"
        1.upto(count) { |i|
            vmname = "ci-subslave-#{floatingip}-#{i}"
            hostip = Vm.create_internal(vmname, nil, slave_master)
            vm = Vm.new(vmname, hostip)
            vm.send_keepalive
            @@vms.push vm
        }

        pp @@vms
        setup_etc_hosts
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
        @@vms.each { |vm|
            Sh.run("scp /etc/hosts #{vm.hostip}:/etc/.", false, 20, 3)
        }
    end

    def Vm.setup_image_from_snapshot
        @@base = "/usr/local/jenkins/slave_scripts/"
        rsh "nova image-create #{@@base_image} ci-jenkins-slave"
        rsh "glance image-download --file #{@@base_image}.qcow2 " +
                "--progress #{@@base_image}"
    end
end

if __FILE__ == $0 then
    count = 1
    count = ARGV[0].to_i unless ARGV[0].nil?
    Vm.create_slaves(count)
    Sh.exit
end

