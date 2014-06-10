#!/usr/bin/env bash

set -ex
set -o pipefail

function build_vm() {
SB=~/contrail-packaging
ANSIBLE=$SB/tools/scripts/config-ansible

# apt-get update
# apt-get -y install sshpass

# e.g. ci-slave-10.0.1.2
HOSTNAME=`curl -s http://169.254.169.254/openstack/2012-08-10/meta_data.json | python -m json.tool | \grep \"name\": | awk -F '\"' '{print $4}'`
HOSTIP=`echo $HOSTNAME  | cut -d '-' -f 3`

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
rm -rf $REPO
mkdir -p $REPO
cd $REPO
repo init -u git@github.com:Juniper/contrail-vnc-private -m mainline/ubuntu-12-04/manifest-havana.xml
repo sync
rm -rf /tmp/cache
ln -sf /home/jenkins/tmp/cache /tmp/cache
python $REPO/third_party/fetch_packages.py 
python $REPO/distro/third_party/fetch_packages.py
scons
cd $REPO/tools/packaging/build/
./packager.py 
# mkdir -p /root/foo/build/packages/ifmap-server/lib
# build/debian/contrail-analytics-venv/opt/contrail/analytics-venv/bin/pip install --upgrade setuptools
}

function misc() {
apt-get -y install virt-manager vnc4server ruby-ronn qemu-kvm qemu-system bridge-utils uml-utilities  module-assistant default-jdk javahelper lvm2
rm -rf /tmp/cache
ln -sf /home/jenkins/tmp/cache /tmp/cache
rm -rf /cs-shared/builder/cache
mkdir -p /cs-shared/builder/cache
ln -sf /cs-shared/builder/cache/ubuntu1204 /cs-shared/builder/cache/ubuntu-12-04
scp -r anantha@ubuntu-build02:/github-build/distro-packages/build/ubuntu1204 /cs-shared/builder/cache/.
}

function bridge_eth0() {
CFG=<<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

auto br0
iface br0 inet dhcp
    bridge_ports eth0
    bridge_stp off
    bridge_fd 0
    bridge_maxwait 0
EOF
echo $CFG > /etc/network/interfaces
service networking restart
}

function nested_kvm() {
echo "options kvm-intel nested=1" > /etc/modprobe.d/kvm-intel.conf
}

function setup_jenkins_slave_image () {
set -ex
instance=$1
image=$2
if [ -z $image ]; then
    image="ci-jenkins-slave"
fi
glance image-delete $image
image_id=`nova list |\grep -w $1 | awk '{print $2}'`
nova image-create --poll $image_id $image
glance image-download --file $image.qcow2 --progress $image
sshpass -p c0ntrail123 scp $image.qcow2 ci-admin@ubuntu-build02:/ci-admin/images/$image.qcow2
}

build_vm
