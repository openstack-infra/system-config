#!/usr/bin/env ruby

require 'contrail-util'

# source ~/anantha/openstackrc
ENV['OS_AUTH_URL']="http://192.168.69.1:5000/v2.0"
ENV['OS_TENANT_ID']="bc4ef31e0f1c4412bddc0b7ac606d5f2"
ENV['OS_TENANT_NAME']="opencontrail-ci"
ENV['OS_USERNAME']="anantha"
ENV['OS_PASSWORD']="anantha123" # $OS_PASSWORD_INPUT

@base_image = "ci-jenkins-slave"
def setup_image
    sh "nova image-create #{@base_image} ci-jenkins-slave-base"
    sh "glance image-download --file #{@base_image}.qcow2 --progress #{@base_image}"
#   sh "glance image-create --disk-format qcow2 --container-format bare --name ci-jenkins-slave-base2 --file ci-jenkins-slave-base.qcow2 --is-public True"
end

def create_instance
    puts "Creating instance.."
    floating_ip = sh %{neutron floatingip-list | \grep -v " 192\." | \grep -m 1 "10\."  | awk '{print $5}'}
    net_id = sh "nova net-list |\grep -w internet | awk '{print $2}'"
    image_id = sh %{glance image-list |\grep " #{@base_image} " | awk '{print $2}'}
    sh "nova boot --flavor 4 --nic net-id=#{net_id} --image #{image_id} ci-#{floating_ip}"

    private_ip = nil
    while true do
        if sh("nova list | \grep ci-#{floating_ip}") =~ /internet=(\d+\.\d+\.\d+\.\d+)/ then
            private_ip = $1
            break
        end
        sleep 3
    end
    port_id = sh "neutron port-list | \grep #{private_ip} | awk '{print $2}'"
    floating_ip_id = sh "neutron floatingip-list |\grep #{floating_ip} | awk '{print $2}'"
    sh "neutron floatingip-associate #{floating_ip_id} #{port_id}"

    puts "Created instance ci-#{floating_ip} with floating ip #{floating_ip}"
end

count = 1
count = ARGV[0].to_i unless ARGV[0].nil?
1.upto(count) {
    create_instance
    sleep 1
}
