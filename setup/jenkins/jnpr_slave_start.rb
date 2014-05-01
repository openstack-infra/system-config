#!/usr/bin/env ruby

# source ~/anantha/openstackrc
# Picks one available from `neutron floatingip-list`

def dry_run?
    return !ENV['DRY_RUN'].nil? && ENV['DRY_RUN'].casecmp("true") == 0
end

def sh (cmd, ignore = false)
    puts "#{cmd}"
    exit_code = 0
    if not dry_run? then
        if cmd =~ /^cd\s+(.*)/ then
            Dir.chdir($1)
        else
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

def setup_image
    sh "nova image-create jnpr-slave-base ci-jenkins-slave-base"
    sh "glance image-download --file ci-jenkins-slave-base.qcow2 --progress ci-jenkins-slave-base"
#   sh "glance image-create --disk-format qcow2 --container-format bare --name ci-jenkins-slave-base2 --file ci-jenkins-slave-base.qcow2 --is-public True"
end

def create_instance
    puts "Creating instance.."
    floating_ip = sh %{neutron floatingip-list | \grep -v " 192\." | \grep -m 1 "10\."  | awk '{print $5}'}
    net_id = sh "nova net-list |\grep -w internet | awk '{print $2}'"
    image_id = sh "glance image-list |\grep ci-jenkins-slave-base | awk '{print $2}'"
    sh "nova boot --flavor 4 --nic net-id=#{net_id} --image #{image_id} ci-#{floating_ip}"

    private_ip = nil
    while true do
        if sh("nova list | \grep ci-#{floating_ip}") =~ /internet=(\d+\.\d+\.\d+\.\d+)/ then
            private_ip = $1
            break
        end
        sleep 5
    end
    port_id = sh "neutron port-list | \grep #{private_ip} | awk '{print $2}'"
    floating_ip_id = sh "neutron floatingip-list |\grep #{floating_ip} | awk '{print $2}'"
    sh "neutron floatingip-associate #{floating_ip_id} #{port_id}"

    puts "Created instance ci=#{floating_ip} with floating ip #{floating_ip}"
end

count = 1
count = ARGV[0].to_i unless ARGV[0].nil?
1.upto(count) {
    create_instance
    sleep 1
}
