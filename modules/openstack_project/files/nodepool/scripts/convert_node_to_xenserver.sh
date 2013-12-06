#!/bin/bash -xe

# Copyright (C) 2011-2013 OpenStack Foundation
# Copyright (c) 2013 Citrix Systems, Inc.
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

set -eux

XENSERVER_PASSWORD="password"

mkdir /xsinst
wget -qO /xsinst/xs62.iso http://downloadns.citrix.com.edgesuite.net/akdlm/8159/XenServer-6.2.0-install-cd.iso
cp /root/.ssh/authorized_keys /xsinst/
mkdir -p /mnt/xs-iso
mount -o loop /xsinst/xs62.iso /mnt/xs-iso
mkdir /opt/xs-install
cp /mnt/xs-iso/install.img /mnt/xs-iso/boot/xen.gz /mnt/xs-iso/boot/vmlinuz /opt/xs-install/
umount /mnt/xs-iso

ADDRESS=$(grep -m 1 "address" /etc/network/interfaces | sed -e 's,^ *,,g' | cut -d " " -f 2)
NETMASK=$(grep -m 1 "netmask" /etc/network/interfaces | sed -e 's,^ *,,g' | cut -d " " -f 2)
GATEWAY=$(grep -m 1 "gateway" /etc/network/interfaces | sed -e 's,^ *,,g' | cut -d " " -f 2)
MACADDRESS=$(ifconfig eth0 | sed -ne 's/.*HWaddr \(.*\)$/\1/p' | tr -d " ")
NAMESERVERS=$(cat /etc/resolv.conf | grep nameserver | cut -d " " -f 2 | sort | uniq | tr '\n' , | sed -e 's/,$//g')
DNS_ADDRESSES=$(echo "$NAMESERVERS" | sed -e "s/,/ /g")
NAMESERVER_ELEMENTS=$(cat /etc/resolv.conf | grep nameserver | cut -d " " -f 2 | sort | uniq | sed -e 's,^,<nameserver>,g' -e 's,$,</nameserver>,g')

# Create a script that will be executed on firstboot of XenServer
cat > /xsinst/95-cloudboot << CLOUDBOOT
#!/bin/bash
set -eux

wget -qO /root/staging_vm.xva http://downloads.vmd.citrix.com/OpenStack/minvm.xva
VM=\$(xe vm-import filename=/root/staging_vm.xva)
rm -f /root/staging_vm.xva

PIF=\$(xe pif-list device=eth0 --minimal)
HOST_INT_NET=\$(xe network-list name-label="Host internal management network" --minimal)

ORIGINAL_MGT_NET=\$(xe pif-param-get param-name=network-uuid uuid=\$PIF)
NEW_MGT_NET=\$(xe network-create name-label=mgt name-description=mgt)
sleep 1
NEW_MGT_VLAN=\$(xe vlan-create vlan=100 pif-uuid=\$PIF network-uuid=\$NEW_MGT_NET)
NEW_PIF=\$(xe pif-list VLAN=100 device=eth0 --minimal)
VM=\$(xe vm-list name-label="Staging VM" --minimal)

xe pif-reconfigure-ip \\
    uuid=\$PIF \\
    mode=static \\
    IP=0.0.0.0 \\
    netmask=0.0.0.0

xe pif-reconfigure-ip \\
    uuid=\$NEW_PIF \\
    mode=static \\
    IP=192.168.33.2 \\
    netmask=255.255.255.0 \\
    gateway=192.168.33.1 \\
    DNS=192.168.33.1

xe host-management-reconfigure pif-uuid=\$NEW_PIF

# Create vifs for the staging VM
xe vif-create vm-uuid=\$VM network-uuid=\$HOST_INT_NET device=0
xe vif-create vm-uuid=\$VM network-uuid=\$ORIGINAL_MGT_NET mac=$MACADDRESS device=1
xe vif-create vm-uuid=\$VM network-uuid=\$NEW_MGT_NET device=2

xe vm-start uuid=\$VM

# Wait until Staging VM is accessible
while ! ping -c 1 "\${VM_IP:-}" > /dev/null 2>&1; do
    VM_IP=\$(xe vm-param-get param-name=networks uuid=\$VM | sed -e 's,^.*0/ip: ,,g' | sed -e 's,;.*$,,g')
    sleep 1
done

rm -f tempkey tempkey.pub
ssh-keygen -f tempkey -P ""

DOMID=\$(xe vm-param-get param-name=dom-id uuid=\$VM)

# Authenticate temporary key to Staging VM
xenstore-write /local/domain/\$DOMID/authorized_keys/user "\$(cat tempkey.pub)"
xenstore-chmod -u /local/domain/\$DOMID/authorized_keys/user "r\$DOMID"

function run_on_vm() {
    ssh \\
        -i tempkey \\
        -o UserKnownHostsFile=/dev/null \\
        -o StrictHostKeyChecking=no \\
        -o BatchMode=yes \\
        "user@\$VM_IP" "\$@"
}

while ! run_on_vm true < /dev/null > /dev/null 2>&1; do
    echo "waiting for key to be activated"
    sleep 1
done

{
cat << EOF
auto eth1
iface eth1 inet static
  address $ADDRESS
  netmask $NETMASK
  gateway $GATEWAY
  dns-nameservers $DNS_ADDRESSES

auto eth2
  iface eth2 inet static
  address 192.168.33.1
  netmask 255.255.255.0
EOF
} | run_on_vm "sudo tee -a /etc/network/interfaces"

# Remove authorized_keys updater
echo "" | run_on_vm sudo crontab -

# Disable temporary private key and reboot
cat /root/.ssh/authorized_keys | run_on_vm "cat > .ssh/authorized_keys && sudo reboot"
CLOUDBOOT

## Remastering the initial root disk
mkdir -p /opt/xs-install/install-remaster/
(
cd /opt/xs-install/install-remaster/
zcat "/opt/xs-install/install.img" | cpio -idum --quiet
cat > answerfile.xml << EOF
<?xml version="1.0"?>
<installation srtype="ext">
<primary-disk preserve-first-partition="false">sda</primary-disk>
<keymap>us</keymap>
<root-password>$XENSERVER_PASSWORD</root-password>
<source type="url">file:///tmp/ramdisk</source>
<admin-interface name="eth0" proto="static">
<ip>$ADDRESS</ip>
<subnet-mask>$NETMASK</subnet-mask>
<gateway>$GATEWAY</gateway>
</admin-interface>
$NAMESERVER_ELEMENTS
<timezone>America/Los_Angeles</timezone>
<script stage="filesystem-populated" type="url">file:///postinst.sh</script>
</installation>
EOF

# After the installer finished, this script will be executed
cat > postinst.sh << EOF
#!/bin/sh
touch \$1/tmp/postinst.sh.executed
cp /tmp/ramdisk/95-cloudboot \$1/etc/firstboot.d/95-cloudboot
chmod 777 \$1/etc/firstboot.d/95-cloudboot
mkdir -p \$1/root/.ssh
chmod 0700 \$1/root/.ssh
cp /tmp/ramdisk/authorized_keys \$1/root/.ssh/authorized_keys
chmod 0600 \$1/root/.ssh/authorized_keys
EOF

find . -print | cpio -o --quiet -H newc | xz --format=lzma > /opt/xs-install/install_modded.img
)


# Deal with grub
sed -ie 's/^GRUB_HIDDEN_TIMEOUT/#GRUB_HIDDEN_TIMEOUT/g' /etc/default/grub
sed -ie 's/^GRUB_HIDDEN_TIMEOUT_QUIET/#GRUB_HIDDEN_TIMEOUT_QUIET/g' /etc/default/grub
# sed -ie 's/^GRUB_TIMEOUT=.*$/GRUB_TIMEOUT=-1/g' /etc/default/grub
sed -ie 's/^.*GRUB_TERMINAL=.*$/GRUB_TERMINAL=console/g' /etc/default/grub

cat > /etc/grub.d/45_xs-install << EOF
cat << XS_INSTALL
menuentry 'XenServer installer' {
    multiboot /opt/xs-install/xen.gz dom0_max_vcpus=1-2 dom0_mem=max:752M com1=115200,8n1 console=com1,vga
    module /opt/xs-install/vmlinuz xencons=hvc console=tty0 console=hvc0 make-ramdisk=/dev/sda1 answerfile=file:///answerfile.xml install
    module /opt/xs-install/install_modded.img
}
XS_INSTALL
EOF

chmod +x /etc/grub.d/45_xs-install

sed -ie 's/GRUB_DEFAULT=0/GRUB_DEFAULT=4/g' /etc/default/grub
update-grub
reboot
