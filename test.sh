#!/bin/bash -e

if [ "$1" = '--three' ]; then
    PUPPET_VERSION=3
    echo "Running in 3 mode"
fi

ROOT=$(readlink -fn $(dirname $0))
MODULE_PATH="${ROOT}/modules:/etc/puppet/modules"

if [[ ! -d applytest ]] ; then
    mkdir applytest
fi

csplit -sf applytest/puppetapplytest manifests/site.pp '/^$/' {*}
sed -i -e 's/^[^][:space:]$]/#&/g' applytest/puppetapplytest*
sed -i -e 's@hiera(.\([^.]*\).,\([^)]*\))@\2@' applytest/puppetapplytest*
mv applytest/*00 applytest/head  # These are the top-level variables defined in site.pp

if [[ `lsb_release -i -s` == 'CentOS' ]]; then
    if [[ `lsb_release -r -s` =~ '6' ]]; then
        CODENAME='centos6'
        if [ $PUPPET_VERSION = '3' ]; then
            sudo sed -i '/exclude.*/d' /etc/yum.repos.d/puppetlabs.repo
            sudo yum install -y puppet
        fi
    fi
elif [[ `lsb_release -i -s` == 'Ubuntu' ]]; then
    CODENAME=`lsb_release -c -s`
    if [ $PUPPET_VERSION = '3' ]; then
        sudo rm /etc/apt/preferences.d/00-puppet.pref
        sudo apt-get install -y puppet
    fi
fi

FOUND=0
for f in `find applytest -name 'puppetapplytest*' -print` ; do
    if grep -q "Node-OS: $CODENAME" $f; then
        cat applytest/head $f > $f.final
        FOUND=1
    fi
done

if [[ $FOUND == "0" ]]; then
    echo "No hosts found for node type $CODENAME"
    exit 1
fi

grep -v 127.0.1.1 /etc/hosts >/tmp/hosts
HOST=`echo $HOSTNAME |awk -F. '{ print $1 }'`
echo "127.0.1.1 $HOST.openstack.org $HOST" >> /tmp/hosts
sudo mv /tmp/hosts /etc/hosts

sudo mkdir -p /var/run/puppet
find applytest -name 'puppetapplytest*.final' -print0 | \
    xargs -0 -P $(nproc) -n 1 -I filearg \
        sudo puppet apply --modulepath=${MODULE_PATH} --noop --verbose --debug filearg > /dev/null
