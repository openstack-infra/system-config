#!/usr/bin/env ruby

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
    return output
end

def setup_hosts
    @HOSTS=<<EOF

127.0.0.1       localhost

148.251.110.19   ci-puppetmaster.opencontrail.org ci-puppetmaster
148.251.110.20   puppetdb.opencontrail.org puppetdb
148.251.110.16   review.opencontrail.org review
148.251.110.18   jenkins.opencontrail.org jenkins
148.251.110.17   zuul.opencontrail.org zuul
148.251.46.180   ci-host.opencontrail.org ci-host

# 192.168.1.10   ci-puppetmaster.opencontrail.org ci-puppetmaster
# 192.168.1.11   puppetdb.opencontrail.org puppetdb
# 192.168.1.12   review.opencontrail.org review
# 192.168.1.13   jenkins.opencontrail.org jenkins
# 192.168.1.14   zuul.opencontrail.org zuul
# 192.168.1.1    ci-host.opencontrail.org ci-host
# 192.168.1.30   jnpr-slave-1.opencontrai.org jnpr-slave-1

192.168.1.15     jenkins01.opencontrail.org jenkins01
192.168.1.16     puppet-dashboard.opencontrail.org puppet-dashboard
192.168.1.100    ubuntu-base-os.opencontrail.org ubuntu-base-os

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

    File.open("/etc/hosts", "w") { |fp| fp.write(@HOSTS} }
end

def setup_networking(name, public_addr, private_addr)
    @IFACE=<<EOF
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
iface eth0 inet static
address #{public_addr}
netmask 255.255.255.240
dns-nameservers 213.133.98.98 nameserver 213.133.99.99 213.133.100.100 2a01:4f8:0:a102::add:9999 2a01:4f8:0:a0a1::add:1010 2a01:4f8:0:a111::add:9898

# gateway 148.251.46.161
# up route add -net 148.251.46.161 netmask 255.255.255.255 eth0

# up route add -net 148.251.110.160 netmask 255.255.255.224 gw 148.251.46.161 eth0
# iface eth0 inet dhcp

auto eth1
iface eth1 inet static
address #{private_addr}
netmask 255.255.255.0
EOF

    @IF_UP_SCRIPT=<<EOF

#!/usr/bin/env bash
#
## Check for specific interface if desired
[ "$IFACE" != "eth0" ] || exit 0

arp -s -i eth0 148.251.46.161 3c:94:d5:4a:ec:90
route add 148.251.46.161/32 dev eth0
route add default gw 148.251.46.161

EOF

    File.open("/etc/hostname", "w") { |fp| fp.write(name) }
    File.open("/etc/network/interfaces", "w") { |fp| fp.write(@IFACE} }
    File.open("/etc/network/if-up.d/script", "w", 0755) { |fp|
        fp.write(@IF_UP_SCRIPT}
}

end

def setup_puppet(name)
    conf = <<EOF
[main]
logdir=/var/log/puppet
vardir=/var/lib/puppet
ssldir=/var/lib/puppet/ssl
rundir=/var/run/puppet
factpath=$vardir/lib/facter
templatedir=$confdir/templates
server=ci-puppetmaster.opencontrail.org
certname=#{name}
pluginsync=true

[master]
# These are needed when the puppetmaster is run by passenger
# # and can safely be removed if webrick is used.
ssl_client_header = SSL_CLIENT_S_DN
ssl_client_verify_header = SSL_CLIENT_VERIFY
manifestdir=/opt/config/$environment/manifests
modulepath=/opt/config/$environment/modules:/etc/puppet/modules
manifest=$manifestdir/site.pp
reports=store

[agent]
report=true
splay=true
runinterval=600
EOF
    File.open("/etc/puppet/puppet.conf", "w") { |fp| fp.write(conf) }
end

setup_hosts
setup_networking("jenkins", "148.251.110.18", "192.168.1.13")
setup_puppet("jenkins")

# Setup /root/.ssh/id_rsa*

def misc
    cmds=<<EOF
scp /etc/hosts ubuntu-base-os:/etc/
scp /etc/hosts review:/etc/
scp /etc/hosts zuul:/etc/
scp /etc/hosts jenkins:/etc/
scp /etc/hosts ci-puppetmaster:/etc/
scp /etc/hosts puppetdb:/etc/
scp /etc/hosts ubuntu-base-os:/etc/

apt-get -y install traceroute wireshark
EOF

end
