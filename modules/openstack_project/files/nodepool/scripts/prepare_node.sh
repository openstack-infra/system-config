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

SUDO=${SUDO:-true}
THIN=${THIN:-true}
PYTHON3=${PYTHON3:-false}
PYPY=${PYPY:-false}
ALL_MYSQL_PRIVS=${ALL_MYSQL_PRIVS:-false}
GIT_BASE=${GIT_BASE:-git://git.openstack.org}

export PUPPET_VERSION=${PUPPET_VERSION:-'2'}

sudo hostname $HOSTNAME
if [ -n "$HOSTNAME" ] && ! grep -q $HOSTNAME /etc/hosts
then
    echo "127.0.1.1 $HOSTNAME" | sudo tee -a /etc/hosts
fi

echo $HOSTNAME > /tmp/image-hostname.txt
sudo mv /tmp/image-hostname.txt /etc/image-hostname.txt

# Fedora image doesn't come with wget
if [ -f /usr/bin/yum ]; then
    sudo yum -y install wget
fi
wget https://git.openstack.org/cgit/openstack-infra/config/plain/install_puppet.sh
sudo bash -xe install_puppet.sh

sudo git clone --depth=1 $GIT_BASE/openstack-infra/config.git \
    /root/config
sudo /bin/bash /root/config/install_modules.sh

set +e
if [ -z "$NODEPOOL_SSH_KEY" ] ; then
    sudo puppet apply --detailed-exitcodes --modulepath=/root/config/modules:/etc/puppet/modules \
        -e "class {'openstack_project::single_use_slave': sudo => $SUDO, thin => $THIN, python3 => $PYTHON3, include_pypy => $PYPY, all_mysql_privs => $ALL_MYSQL_PRIVS, }"
    PUPPET_RET_CODE=$?
else
    sudo puppet apply --detailed-exitcodes --modulepath=/root/config/modules:/etc/puppet/modules \
        -e "class {'openstack_project::single_use_slave': install_users => false, sudo => $SUDO, thin => $THIN, python3 => $PYTHON3, include_pypy => $PYPY, all_mysql_privs => $ALL_MYSQL_PRIVS, ssh_key => '$NODEPOOL_SSH_KEY', }"
    PUPPET_RET_CODE=$?
fi
# Puppet doesn't properly return exit codes. Check here the values that
# indicate failure of some sort happened. 0 and 2 indicate success.
if [ "$PUPPET_RET_CODE" -eq "4" ] || [ "$PUPPET_RET_CODE" -eq "6" ] ; then
    exit $PUPPET_RET_CODE
fi
set -e

# The puppet modules should install unbound.  Set up some nameservers.
cat >/tmp/forwarding.conf <<EOF
forward-zone:
  name: "."
  forward-addr: 8.8.8.8
EOF
sudo mv /tmp/forwarding.conf /etc/unbound/
sudo chown root:root /etc/unbound/forwarding.conf
sudo chmod a+r /etc/unbound/forwarding.conf
# HPCloud has selinux enabled by default, Rackspace apparently not.
# Regardless, apply the correct context.
if [ -x /sbin/restorecon ] ; then
    sudo chcon system_u:object_r:named_conf_t:s0 /etc/unbound/forwarding.conf
fi

# Overwrite /etc/resolv.conf at boot
sudo dd of=/etc/rc.local <<EOF
#!/bin/bash
set -o xtrace

# Some providers inject dynamic network config statically. Work around this
# for DNS nameservers. This is expected to fail on some nodes so remove -e.
set +e
sed -i -e 's/^\(DNS[0-9]*=[.0-9]\+\)/#\1/g' /etc/sysconfig/network-scripts/ifcfg-*
set -e

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

# Make sure DNS works.
dig git.openstack.org

# Cache all currently known gerrit repos.
sudo mkdir -p /opt/git
sudo -i python /opt/nodepool-scripts/cache_git_repos.py $GIT_BASE

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

# Remove cron jobs
# We create fresh servers for these hosts, and they are used once. They don't
# need to do things like update the locatedb or the mandb or rotate logs
# or really any of those things. We only want code running here that we want
# here.
sudo rm -f /etc/cron.{monthly,weekly,daily,hourly,d}/*

# Install Zuul into a virtualenv
# This is in /usr instead of /usr/local due to this bug on precise:
# https://bugs.launchpad.net/ubuntu/+source/python2.7/+bug/839588
git clone /opt/git/openstack-infra/zuul /tmp/zuul
sudo virtualenv /usr/zuul-env
sudo /usr/zuul-env/bin/pip install /tmp/zuul
sudo rm -fr /tmp/zuul

sync
sleep 5
