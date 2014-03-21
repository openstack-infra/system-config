#!/bin/bash -xe

# Copyright (C) 2011-2013 OpenStack Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
#
# See the License for the specific language governing permissions and
# limitations under the License.

HOSTNAME=$1
SUDO=$2
BARE=$3
PYTHON3=${4:-false}
PYPY=${5:-false}
ALL_MYSQL_PRIVS=${6:-false}

# Save the nameservers configured by our provider.
echo 'forward-zone:' > /tmp/forwarding.conf
echo '  name: "."' >> /tmp/forwarding.conf
# HPCloud nameservers (which have 10. addresses) strip RRSIG records.
# Until this is resolved, use google instead.
if grep "^nameserver \(10\|206\)\." /etc/resolv.conf; then
    echo "  forward-addr: 8.8.8.8">> /tmp/forwarding.conf
else
    grep "^nameserver" /etc/resolv.conf|sed 's/nameserver \(.*\)/  forward-addr: \1/' >> /tmp/forwarding.conf
fi

sudo hostname $HOSTNAME
# Fedora image doesn't come with wget
if [ -f /usr/bin/yum ]; then
    sudo yum -y install wget
fi
wget https://git.openstack.org/cgit/openstack-infra/config/plain/install_puppet.sh
sudo bash -xe install_puppet.sh
sudo git clone --depth=1 git://git.openstack.org/openstack-infra/config.git \
    /root/config
sudo /bin/bash /root/config/install_modules.sh
if [ -z "$NODEPOOL_SSH_KEY" ] ; then
    sudo puppet apply --modulepath=/root/config/modules:/etc/puppet/modules \
	-e "class {'openstack_project::single_use_slave': sudo => $SUDO, bare => $BARE, python3 => $PYTHON3, include_pypy => $PYPY, all_mysql_privs => $ALL_MYSQL_PRIVS, }"
else
    sudo puppet apply --modulepath=/root/config/modules:/etc/puppet/modules \
	-e "class {'openstack_project::single_use_slave': install_users => false, sudo => $SUDO, bare => $BARE, python3 => $PYTHON3, include_pypy => $PYPY, all_mysql_privs => $ALL_MYSQL_PRIVS, ssh_key => '$NODEPOOL_SSH_KEY', }"
fi

# The puppet modules should install unbound.  Take the nameservers
# that we ended up with at boot and configure unbound to forward to
# them.
sudo mv /tmp/forwarding.conf /etc/unbound/
sudo chown root:root /etc/unbound/forwarding.conf
sudo chmod a+r /etc/unbound/forwarding.conf
# HPCloud has selinux enabled by default, Rackspace apparently not.
# Regardless, apply the correct context.
if [ -x /sbin/restorecon ] ; then
    sudo chcon system_u:object_r:named_conf_t:s0 /etc/unbound/forwarding.conf
fi

sudo bash -c "echo 'include: /etc/unbound/forwarding.conf' >> /etc/unbound/unbound.conf"
sudo /etc/init.d/unbound restart

# Make sure DNS works.
dig git.openstack.org

# Cache all currently known gerrit repos.
sudo mkdir -p /opt/git
sudo -i python /opt/nodepool-scripts/cache_git_repos.py

# We don't always get ext4 from our clouds, mount ext3 as ext4 on the next
# boot (eg when this image is used for testing).
sudo sed -i 's/ext3/ext4/g' /etc/fstab

# Remove additional sources used to install puppet or special version of pypi.
# We do this because leaving these sources in place causes every test that
# does an apt-get update to hit those servers which may not have the uptime
# of our local mirrors.
OS_FAMILY=$(facter osfamily)
if [ "$OS_FAMILY" == "Debian" ] ; then
    sudo rm -f /etc/apt/sources.list.d/*
    sudo apt-get update
elif [ "$OS_FAMILY" == "RedHat" ] ; then
    # Can't delete * in yum.repos.d since all of the repos are listed there.
    # Be specific instead.
    if [ -f /etc/yum.repos.d/puppetlabs.repo ] ; then
        sudo rm -f /etc/yum.repos.d/puppetlabs.repo
    fi
fi

sync
sleep 5
