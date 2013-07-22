#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if cat /etc/*release | grep -e "CentOS" -e "Red Hat" &> /dev/null; then

	rpm -qi epel-release &> /dev/null || rpm -Uvh http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
        #installing this package gives use the key
	rpm -ivh http://yum.puppetlabs.com/el/6/products/x86_64/puppetlabs-release-6-6.noarch.rpm
	cat > /etc/yum.repos.d/puppetlabs.repo <<-"EOF"
	[puppetlabs-products]
	name=Puppet Labs Products El 6 - $basearch
	baseurl=http://yum.puppetlabs.com/el/6/products/$basearch
	gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-puppetlabs
	enabled=1
	gpgcheck=1
	exclude=puppet-2.8* puppet-2.9* puppet-3*
	EOF
	yum update -y
	# NOTE: enable the optional-rpms channel (if not already enabled)
	# yum-config-manager --enable rhel-6-server-optional-rpms

        # NOTE: we preinstall lsb_release to ensure facter sets lsbdistcodename
	yum install -y redhat-lsb-core git puppet

else #defaults to Ubuntu

	cat > /etc/apt/preferences.d/00-puppet.pref <<-EOF
	Package: puppet puppet-common puppetmaster puppetmaster-common
	Pin: version 2.7*
	Pin-Priority: 501
	EOF

	lsbdistcodename=`lsb_release -c -s`
	puppet_deb=puppetlabs-release-${lsbdistcodename}.deb
	wget http://apt.puppetlabs.com/$puppet_deb -O $puppet_deb
	dpkg -i $puppet_deb

	apt-get update
	apt-get dist-upgrade
	apt-get install -y puppet git rubygems

fi

git clone https://git.openstack.org/openstack-infra/config
bash config/install_modules.sh

puppet apply --modulepath=`pwd`/config/modules:/etc/puppet/modules -e 'node default {class { "openstack_project::bare_slave": install_users => false }}'
