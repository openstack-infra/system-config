#!/usr/bin/env bash

set -ex
set -o pipefail

function build_vm() {
SB=~/contrail-packaging
ANSIBLE=$SB/tools/scripts/config-ansible

# apt-get update
# apt-get -y install sshpass

HOSTNAME=`curl -s http://169.254.169.254/openstack/2012-08-10/meta_data.json | python -m json.tool | \grep \"name\": | awk -F '\"' '{print $4}'`
HOSTIP=`echo $HOSTNAME  | cut -d '-' -f 2`

if [ ! -f $SB/tools/scripts/config-ansible ]; then
    rm -rf $SB
    git clone git@github.com:Juniper/contrail-packaging.git $SB
fi

if ! grep -q Contrail-Ansible ~/.ssh/authorized_keys; then
    python $ANSIBLE -i $HOSTIP -r contrail-ec-build03.juniper.net key
fi

python $ANSIBLE -n $HOSTNAME -i $HOSTIP -r contrail-ec-build03.juniper.net -d ubuntu-12-04 config
}

# wget https://bitbucket.org/pypa/setuptools/raw/0.7.4/ez_setup.py -O - | python
# scp -r anantha@ubuntu-build02:/github-build/distro-packages/build/ubuntu1204 /github-build/distro-packages/build/.
# pip install --upgrade pip

function build_contrail() {
repo init -u git@github.com:Juniper/contrail-vnc-private -m mainline/ubuntu-12-04/manifest-havana.xml
python $REPO/third_party/fetch_packages.py 
python $REPO/distro/third_party/fetch_packages.py
scons -c $REPO/build/third_party/log4cplus/
scons $REPO/build/third_party/log4cplus/
cd $REPO/tools/packaging/build/
./packager.py 
# build/debian/contrail-analytics-venv/opt/contrail/analytics-venv/bin/pip install --upgrade setuptools
}
