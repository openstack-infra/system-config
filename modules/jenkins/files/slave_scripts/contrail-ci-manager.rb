#!/usr/bin/env ruby

require 'pp'
ENV['USER'] = "jenkins" if ENV['USER'].nil? or ENV['USER'].empty?
@exit = 0

class Sh
    @ignore_failed_exit_code = false

    def Sh.dry_run?
        return !ENV['DRY_RUN'].nil? && ENV['DRY_RUN'].casecmp("true") == 0
    end

    def Sh.run (cmd, ignore = @ignore_failed_exit_code)
        puts "#{cmd}"
        exit_code = 0
        if not dry_run? then
            if cmd =~ /^cd\s+(.*)/ then
                Dir.chdir($1)
            else
                puts cmd
                output = `#{cmd}`
                exit_code = $?.to_i unless ignore
            end
        end
        puts output if !output.nil? and !output.empty?

        if exit_code != 0 then
            puts "Comamnd #{cmd} failed with exit code #{$?}"
            exit exit_code
        end
        return output.chomp
    end

    def Sh.crun (cmd, ignore = true, cloud_manager = "10.84.26.14")
        return sh("ssh #{cloud_manager} #{cmd}", ignore)
    end
end

class Vm
    attr_accessor hostname, hostip
    attr_reader type

    CI_SLAVE = 1
    CI_SUB_SLAVE = 2
    CI_UNKNOWN = 3

    @@base = "/usr/local/jenkins/slave_scripts/"
    @@base_image = "ci-jenkins-slave"
    @@vms = [ ]

    def initialize(hostname, hostip, type)
        @hostname = hostname
        @hostip = hostip
        @type = type
    end

    def delete
        Sh.crun "#{@base}/contrail-ci-openstack.sh nova delete #{@hostname}"
        @thread.kill unless @thread.nil?
    end

    def Vm.clean_all
        @vms.each { |vm| vm.delete }
    end

    def send_keepalive
        # VMs self-destruct themselves unless we periodically ping.
        @thread = Thread.new {
            kfile = "/root/#{hostname}-jenkins-keepalive.log"
            loop do
                t = Time.now
                puts "Updating time #{t}"
                File.open(kfile, "w") {|fp| t.to_a.each {|i| fp.puts i}}
                sh "scp #{kfile} root@#{@hostip}:#{kfile}", true
                sleep 2
            end
        }
    end

    def Vm.get_hostname
        return sh %{curl -s http://169.254.169.254/openstack/2012-08-10/meta_data.json | python -m json.tool | \grep \\"name\\": | awk -F '\"' '{print $4}'}
    end

    def Vm.get_hostip (hostname = get_hostname)
        return $1 if hostname =~ /ci-(.*)/
        return "127.0.0.1"
    end

    def Vm.get_mode
        mode = sh %{curl -s http://169.254.169.254/openstack/2012-08-10/meta_data.json | python -m json.tool | \grep \\"ci-node-type\\": | awk -F '\"' '{print $4}'}
        return CI_SLAVE if mode == "ci-slave"
        return CI_SUB_SLAVE if mode == "ci-sub-slave"

        return CI_UNKNOWN
    end

    def Vm.check_keepalive(hostname)
        # Check if I am indeed systest runner slave.

        # Read the time object, periodically updated by the master.
        last_updated = Time.now
        kfile = "/root/#{hostname}-jenkins-keepalive.log"
        loop do
        last_updated = File.open(kfile, "r") { |fp| Time.mktime *fp.readlines }\
            if File.file? kfile
        elapsed = (Time.now - last_updated)/60
        puts "#{hostname}: #{elapsed} minutes elapsed since last update"

        # If it is not updated within 5 minutes, commit suicide!
        Sh.crun "#{@@base}/ci-openstack.sh nova delete #{hostname}" \
            if elapsed > 5
        sleep 10
        end
    end

    def Vm.create_internal(type)
        puts "Creating VM.."
        floating_ip = Sh.crun %{neutron floatingip-list | \grep -v " 192\." | \grep -m 1 "10\."  | awk '{print $5}'}
        net_id = Sh.crun "nova net-list |\grep -w internet | awk '{print $2}'"
        image_id = Sh.crun %{glance image-list |\grep " #{@base_image} " | awk '{print $2}'}
        Sh.crun "nova boot --flavor 4 --nic net-id=#{net_id} --image #{image_id} ci-#{floating_ip}"

        private_ip = nil
        while true do
            if Sh.crun("nova list | \grep ci-#{floating_ip}") =~
                    /internet=(\d+\.\d+\.\d+\.\d+)/ then
                private_ip = $1
                break
            end
            sleep 3
        end
        port_id =
            Sh.crun "neutron port-list | \grep #{private_ip} | awk '{print $2}'"
        floating_ip_id = Sh.crun "neutron floatingip-list |\grep #{floating_ip} | awk '{print $2}'"
        Sh.crun "neutron floatingip-associate #{floating_ip_id} #{port_id}"

        hostname = "ci-#{floating_ip}"
        puts "Created instance #{hostname} with floating ip #{floating_ip}"
        sleep 1

        @@vms.push Vm.new(hostname, floating_ip, type)
        send_keepalive if type == CI_SUB_SLAVE
        return @@vms.last
    end

    def Vm.create(type, count = 1)
        1.upto(count) { Vm.create_internal }
    end

    def Vm.setup_image_from_snapshot
        rsh "nova image-create #{@@base_image} ci-jenkins-slave"
        rsh "glance image-download --file #{@@base_image}.qcow2 " +
                "--progress #{@@base_image}"
    end

    def Vm.auto_setup
        hostname = get_hostname()
        hostip = Vm.get_hostip(hostname)

        sh "\grep #{hostname} /etc/hosts || echo #{hostip} #{hostname} >> /etc/hosts"
        sh "echo #{hostname} > /etc/hostname"
        sh "service hostname restart"

        mode = get_mode

        # CI-SubSlaves check for keep-alives from the slave owner.
        check_keepalive(hostname) if mode == CI_SUB_SLAVE

        # CI-Slaves register to jenkins.opencontrail.org
        exec %{java -jar /root/swarm-client-1.15-jar-with-dependencies.jar -labels juniper-tests -mode normal -master http://jenkins.opencontrail.org:8080/ -fsroot /home/jenkins -username ci-admin-f -password bf33d8e02sdfdskjfdsj4f41dc3aa4cab6d90cefa64 -name #{get_hostname} 2>&1 | tee /root/jenkins-slave.log} if mode == CI_SLAVE
    end
end

def master
    run_tests if start_vms(2)
    Vm.clean_all
end

# This script provides following functionalities.
# 1. Act as CI slave and register with jenkins.opencontrail.org master
# 2. Launch as many CI slaves as desired
# 2. Act as CI Test slave for another CI Slave for sanity tests
# 3. Launch as many CI Test slaves as desired
#        Run a user script after CI Test slaves are up and running
#        Maintain keepalices with CI Test slaves
#        If this script ends/terminated, CI Test slaves kill themselves!
# 4. Prepare contrail gerrit workspace

pp ENV
count = 1
count = ARGV[0].to_i unless ARGV[0].nil?
create_multiple_instances(count)

ARGV[0] == "master" ? master : slave

exit(@exit)
