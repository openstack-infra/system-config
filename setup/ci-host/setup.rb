#!/usr/bin/env bash

HOSTS=<<EOF

192.168.1.10     ci-puppetmaster.opencontrail.org ci-puppetmaster
192.168.1.11     puppetdb.opencontrail.org puppetdb
192.168.1.12     review.opencontrail.org review
192.168.1.13     jenkins.opencontrail.org jenkins
192.168.1.14     zuul.opencontrail.org zuul
192.168.1.15     jenkins01.opencontrail.org jenkins01
192.168.1.16     puppet-dashboard.opencontrail.org puppet-dashboard
192.168.1.100    ubuntu-base-os.opencontrail.org ubuntu-base-os
192.168.1.1      ci-host.opencontrail.org ci-host

EOF

cat $HOSTS >> /etc/hosts

# Setup /root/.ssh/id_rsa*

scp /etc/hosts ubuntu-base-os:/etc/
scp /etc/hosts review:/etc/
scp /etc/hosts zuul:/etc/
scp /etc/hosts jenkins:/etc/
scp /etc/hosts ci-puppetmaster:/etc/
scp /etc/hosts puppetdb:/etc/
scp /etc/hosts ubuntu-base-os:/etc/

apt-get -y install traceroute wireshark
