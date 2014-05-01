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
ENABLE_UNBOUND=true
GIT_PROTOCOL=git
if [ -n "$NODEPOOL_HTTP_PROXY" ]; then
    export http_proxy=$NODEPOOL_HTTP_PROXY
    export https_proxy=$NODEPOOL_HTTPS_PROXY
    export no_proxy=$NODEPOOL_NO_PROXY
    sudo bash -xe sudo_keep_proxy_settings.sh
    sudo bash -xe sudo_install_proxy_settings.sh
    ENABLE_UNBOUND=false
    GIT_PROTOCOL=http
else
    # Save the nameservers configured by our provider.
    cat >/tmp/forwarding.conf <<EOF
forward-zone:
  name: "."
  forward-addr: 8.8.8.8
EOF
fi

sudo hostname $HOSTNAME
# Fedora image doesn't come with wget
if [ -f /usr/bin/yum ]; then
    sudo yum -y install wget
fi
wget https://git.openstack.org/cgit/openstack-infra/config/plain/install_puppet.sh
sudo bash -xe install_puppet.sh

sudo git clone --depth=1 $GIT_PROTOCOL://git.openstack.org/openstack-infra/config.git \
    /root/config

sudo bash -xe /root/config/install_modules.sh
if [ -z "$NODEPOOL_SSH_KEY" ] ; then
    sudo puppet apply --modulepath=/root/config/modules:/etc/puppet/modules \
	-e "class {'openstack_project::single_use_slave':
                sudo => $SUDO,
                bare => $BARE,
                python3 => $PYTHON3,
                include_pypy => $PYPY,
                all_mysql_privs => $ALL_MYSQL_PRIVS,
                enable_unbound => $ENABLE_UNBOUND,
        }"
else
    sudo puppet apply --modulepath=/root/config/modules:/etc/puppet/modules \
	-e "class {'openstack_project::single_use_slave':
                install_users => false,
                sudo => $SUDO,
                bare => $BARE,
                python3 => $PYTHON3,
                include_pypy => $PYPY,
                all_mysql_privs => $ALL_MYSQL_PRIVS,
                ssh_key => '$NODEPOOL_SSH_KEY',
                enable_unbound => $ENABLE_UNBOUND,
        }"
fi

if [ $ENABLE_UNBOUND == true ]; then
    # Overwrite /etc/resolv.conf at boot
    sudo dd of=/etc/rc.local <<EOF
#!/bin/bash
set -e
set -o xtrace

echo 'nameserver 127.0.0.1' > /etc/resolv.conf

exit 0
EOF

    sudo bash -c "echo 'include: /etc/unbound/forwarding.conf' >> /etc/unbound/unbound.conf"
    if [ -e /etc/init.d/unbound ] ; then
        sudo /etc/init.d/unbound restart
    elif [ -e /usr/lib/systemd/system/unbound.service ] ; then
        sudo systemctl restart unbound
    else
        echo "Can't discover a method to restart \"unbound\""
        exit 1
    fi
fi

# Make sure DNS works.
dig git.openstack.org

# Cache all currently known gerrit repos.
sudo mkdir -p /opt/git
sudo -i python /opt/nodepool-scripts/cache_git_repos.py --git-protocol $GIT_PROTOCOL

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
