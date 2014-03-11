#!/bin/bash

# Copyright (C) 2011-2014 OpenStack Foundation
# Copyright (c) 2014 Citrix Systems, Inc.
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

# Installation
# ~~~~~~~~~~~~
# 1.) Start an Ubuntu HVM instance in the Rackspace cloud.
# 2.) Copy the files from this directory to the instance.
# 3.) Execute this script on the instance with 3 parameters:
#   - First parameter is the password for the XenServer
#   - Second parameter is a URL to an xva appliance to be installed. For
#     building such an appliance, see:
#        https://github.com/citrix-openstack/openstack-xenapi-testing-xva
#   - Third parameter should be the name-label for the appliance.
# 4.) Poll the public IP through ssh, and Wait until the file
#     "$FILE_TO_TOUCH_ON_COMPLETION" exists
#
#
# Snapshots
# ~~~~~~~~~
# 1.) Delete "$FILE_TO_TOUCH_ON_COMPLETION"
# 2.) Create snapshot
# 3.) When booting instances from the snapshot, poll
#     "$FILE_TO_TOUCH_ON_COMPLETION"
#
#
# Details
# ~~~~~~~
# WARINING: This script is a workaround, and should only be used for test
# purposes.
#
# This script will install itself as a boot-time script, and will be executed
# on each system startup. It shrinks the actual Ubuntu installation, and will
# install a XenServer on the remaining space. This script will also be
# installed as a startup script in XenServer. After the installation, whenever
# the instance is restarted, Ubuntu will boot, the networking parameters will
# be copied to a file, and the instance will be automatically rebooted into
# XenServer, where the networking will be adjusted, according to the saved
# parameters. This trickery is needed, because config drive does not include
# the networking parameters.
#
# The appliance will be accessible through the public IP of the instance,
# and dom0 could be accessed from the instance, on the IP address:
#    192.168.33.2
#
# Logging
# ~~~~~~~
# All the output of this script is logged to $0.log

set -eux

THIS_FILE="$(readlink -f $0)"
THIS_DIR="$(dirname $THIS_FILE)"
INSTALL_DIR="$(dirname $THIS_FILE)"
STATE_FILE="${THIS_FILE}.state"
LOG_FILE="${THIS_FILE}.log"
ADDITIONAL_PARAMETERS="$@"

XENSERVER_PASSWORD="$1"
XENSERVER_ISO_URL="http://downloadns.citrix.com.edgesuite.net/akdlm/8159/XenServer-6.2.0-install-cd.iso"
STAGING_APPLIANCE_URL="$2"
APPLIANCE_NAME="$3"
FILE_TO_TOUCH_ON_COMPLETION="/var/run/xenserver.ready"

# It is assumed, that the appliance has a user, DOMZERO_USER, and by
# writing the /local/domain/$DOMID/authorized_keys/$DOMZERO_USER xenstore
# key, the key's contents will be copied into this user's authorized_keys file
DOMZERO_USER=domzero

# Do not change this variable, as this path is hardcoded into XenServer's
# installer. The installer will look for this directory on the device
# specified by the boot parameter make-ramdisk, and copy the contents of this
# directory to ramdisk.
XSINST_DIRECTORY="/xsinst"

function main() {
    case "$(get_state)" in
        "START")
            dump_disk_config
            run_this_script_on_each_boot
            download_xenserver_files /root/xenserver.iso
            download_appliance "$STAGING_APPLIANCE_URL"
            create_ramdisk_contents /root/xenserver.iso
            extract_xs_installer /root/xenserver.iso /opt/xs-install
            generate_xs_installer_grub_config /opt/xs-install file:///tmp/ramdisk/answerfile.xml
            configure_grub
            update-grub
            create_resizing_initramfs_config
            update-initramfs -u
            set_state "SETUP_INSTALLER"
            reboot
            ;;
        "SETUP_INSTALLER")
            dump_disk_config
            delete_resizing_initramfs_config
            update-initramfs -u
            store_cloud_settings "$XSINST_DIRECTORY/cloud-settings"
            store_authorized_keys "$XSINST_DIRECTORY/authorized_keys"
            set_xenserver_installer_as_nextboot
            set_state "XENSERVER_FIRSTBOOT"
            reboot
            ;;
        "XENSERVER_FIRSTBOOT")
            wait_for_xapi
            forget_networking
            transfer_settings_to_appliance "/root/cloud-settings"
            add_boot_config_for_ubuntu /mnt/ubuntu/boot /boot/
            start_ubuntu_on_next_boot /boot/
            set_state "UBUNTU"
            sync
            create_done_file_on_appliance
            ;;
        "UBUNTU")
            mount_dom0_fs /mnt/dom0
            wait_for_networking
            store_cloud_settings /mnt/dom0/root/cloud-settings
            store_authorized_keys /mnt/dom0/root/.ssh/authorized_keys
            start_xenserver_on_next_boot /mnt/dom0/boot
            set_state "XENSERVER"
            reboot
            ;;
        "XENSERVER")
            wait_for_xapi
            forget_networking
            transfer_settings_to_appliance "/root/cloud-settings"
            start_ubuntu_on_next_boot /boot/
            set_state "UBUNTU"
            sync
            create_done_file_on_appliance
            ;;
    esac
}

function set_state() {
    local state

    state="$1"

    echo "$state" > $STATE_FILE
}

function get_state() {
    if [ -e "$STATE_FILE" ]; then
        cat $STATE_FILE
    else
        echo "START"
    fi
}

function create_resizing_initramfs_config() {
    cp "$THIS_DIR/xenserver_helper_initramfs_hook.sh" \
        /usr/share/initramfs-tools/hooks/resize
    chmod +x /usr/share/initramfs-tools/hooks/resize

    cp "$THIS_DIR/xenserver_helper_initramfs_premount.sh" \
        /usr/share/initramfs-tools/scripts/local-premount/resize
    chmod +x /usr/share/initramfs-tools/scripts/local-premount/resize
}

function delete_resizing_initramfs_config() {
    rm -f /usr/share/initramfs-tools/hooks/resize
    rm -f /usr/share/initramfs-tools/scripts/local-premount/resize
}

function run_this_script_on_each_boot() {
    cat > /etc/init/xenserver.conf << EOF
start on stopped rc RUNLEVEL=[2345]

task

script
    /bin/bash $THIS_FILE $ADDITIONAL_PARAMETERS >> $LOG_FILE 2>&1
end script
EOF
}

function create_done_file_on_appliance() {
    while ! echo "sudo touch $FILE_TO_TOUCH_ON_COMPLETION" | bash_on_appliance; do
        sleep 1
    done
}

function download_xenserver_files() {
    local tgt

    tgt="$1"

    wget -qO "$tgt" "$XENSERVER_ISO_URL"
}

function download_appliance() {
    local appliance_url

    appliance_url="$1"

    wget -qO /root/staging_vm.xva "$appliance_url"
}

function print_answerfile() {
    local repository
    local postinst
    local xenserver_pass

    repository="$1"
    postinst="$2"
    xenserver_pass="$3"

    cat << EOF
<?xml version="1.0"?>
<installation srtype="ext">
<primary-disk preserve-first-partition="true">sda</primary-disk>
<keymap>us</keymap>
<root-password>$xenserver_pass</root-password>
<source type="url">$repository</source>
<admin-interface name="eth0" proto="static">
<ip>192.168.34.2</ip>
<subnet-mask>255.255.255.0</subnet-mask>
<gateway>192.168.34.1</gateway>
</admin-interface>
<timezone>UTC</timezone>
<script stage="filesystem-populated" type="url">$postinst</script>
</installation>
EOF
}

function print_postinst_file() {
    local rclocal
    rclocal="$1"

    cat << EOF
#!/bin/sh
touch \$1/tmp/postinst.sh.executed
cp \$1/etc/rc.d/rc.local \$1/etc/rc.d/rc.local.backup
cat $rclocal >> \$1/etc/rc.d/rc.local
cp /tmp/ramdisk/cloud-settings \$1/root/
cp /tmp/ramdisk/authorized_keys \$1/root/.ssh/
EOF
}

function print_rclocal() {
    cat << EOF
# This is the contents of the rc.local file on XenServer
mkdir -p /mnt/ubuntu
mount /dev/sda1 /mnt/ubuntu
mkdir -p $(dirname $INSTALL_DIR)
[ -L $INSTALL_DIR ] || ln -s /mnt/ubuntu${INSTALL_DIR} $INSTALL_DIR
/bin/bash $THIS_FILE $ADDITIONAL_PARAMETERS >> $LOG_FILE 2>&1
EOF
}

function create_ramdisk_contents() {
    local isofile
    local target_dir

    isofile="$1"
    target_dir="$XSINST_DIRECTORY"

    mkdir "$target_dir"
    ln "$isofile" "$target_dir/xenserver.iso"
    print_rclocal > "$target_dir/rclocal"
    print_postinst_file "/tmp/ramdisk/rclocal" > "$target_dir/postinst.sh"
    print_answerfile \
        "file:///tmp/ramdisk" \
        "file:///tmp/ramdisk/postinst.sh" \
        "$XENSERVER_PASSWORD" > "$target_dir/answerfile.xml"
}

function extract_xs_installer() {
    local isofile
    local targetpath

    isofile="$1"
    targetpath="$2"

    local mountdir

    mountdir=$(mktemp -d)
    mount -o loop $isofile $mountdir
    mkdir -p $targetpath
    cp \
        $mountdir/install.img \
        $mountdir/boot/xen.gz \
        $mountdir/boot/vmlinuz \
        $targetpath
    umount $mountdir
}

function generate_xs_installer_grub_config() {
    local bootfiles
    local answerfile

    bootfiles="$1"
    answerfile="$2"

    cat > /etc/grub.d/45_xs-install << EOF
#!/bin/sh
exec tail -n +3 \$0
menuentry 'XenServer installer' {
    multiboot $bootfiles/xen.gz dom0_max_vcpus=1-2 dom0_mem=max:752M com1=115200,8n1 console=com1,vga
    module $bootfiles/vmlinuz xencons=hvc console=tty0 console=hvc0 make-ramdisk=/dev/sda1 answerfile=$answerfile install
    module $bootfiles/install.img
}
EOF
    chmod +x /etc/grub.d/45_xs-install
}

function configure_grub() {
    sed -ie 's/^GRUB_HIDDEN_TIMEOUT/#GRUB_HIDDEN_TIMEOUT/g' /etc/default/grub
    sed -ie 's/^GRUB_HIDDEN_TIMEOUT_QUIET/#GRUB_HIDDEN_TIMEOUT_QUIET/g' /etc/default/grub
    # sed -ie 's/^GRUB_TIMEOUT=.*$/GRUB_TIMEOUT=-1/g' /etc/default/grub
    sed -ie 's/^.*GRUB_TERMINAL=.*$/GRUB_TERMINAL=console/g' /etc/default/grub
    sed -ie 's/GRUB_DEFAULT=0/GRUB_DEFAULT=saved/g' /etc/default/grub
}

function set_xenserver_installer_as_nextboot() {
    grub-set-default "XenServer installer"
}

function store_cloud_settings() {
    local targetpath

    targetpath="$1"

    cat > $targetpath << EOF
ADDRESS=$(grep -m 1 "address" /etc/network/interfaces | sed -e 's,^ *,,g' | cut -d " " -f 2)
NETMASK=$(grep -m 1 "netmask" /etc/network/interfaces | sed -e 's,^ *,,g' | cut -d " " -f 2)
GATEWAY=$(grep -m 1 "gateway" /etc/network/interfaces | sed -e 's,^ *,,g' | cut -d " " -f 2)
MACADDRESS=$(ifconfig eth0 | sed -ne 's/.*HWaddr \(.*\)$/\1/p' | tr -d " ")
NAMESERVERS=$(cat /etc/resolv.conf | grep nameserver | cut -d " " -f 2 | sort | uniq | tr '\n' , | sed -e 's/,$//g')
EOF
}

function store_authorized_keys() {
    local targetpath

    targetpath="$1"

    cp /root/.ssh/authorized_keys $1
}

function wait_for_xapi() {
    while ! [ -e /var/run/xapi_init_complete.cookie ]; do
        sleep 1
    done
}

function forget_networking() {
    xe host-management-disable
    IFS=,
    for vlan in $(xe vlan-list --minimal); do
        xe vlan-destroy uuid=$vlan
    done

    unset IFS
    IFS=,
    for pif in $(xe pif-list --minimal); do
        xe pif-forget uuid=$pif
    done
    unset IFS
}

function add_boot_config_for_ubuntu() {
    local ubuntu_bootfiles
    local bootfiles

    ubuntu_bootfiles="$1"
    bootfiles="$2"

    local kernel
    local initrd

    kernel=$(ls -1c $ubuntu_bootfiles/vmlinuz-* | head -1)
    initrd=$(ls -1c $ubuntu_bootfiles/initrd.img-* | head -1)

    cp $kernel $bootfiles/vmlinuz-ubuntu
    cp $initrd $bootfiles/initrd-ubuntu

    cat >> $bootfiles/extlinux.conf << UBUNTU
label ubuntu
    LINUX $bootfiles/vmlinuz-ubuntu
    APPEND root=/dev/xvda1 ro quiet splash
    INITRD $bootfiles/initrd-ubuntu
UBUNTU
}

function start_ubuntu_on_next_boot() {
    local bootfiles

    bootfiles="$1"

    sed -ie 's,default xe-serial,default ubuntu,g' $bootfiles/extlinux.conf
}

function start_xenserver_on_next_boot() {
    local bootfiles

    bootfiles="$1"

    sed -ie 's,default ubuntu,default xe-serial,g' $bootfiles/extlinux.conf
}

function mount_dom0_fs() {
    local target

    target="$1"

    mkdir -p $target
    mount /dev/xvda2 $target
}

function wait_for_networking() {
    while ! ping -c 1 xenserver.org > /dev/null 2>&1; do
        sleep 1
    done
}

function bash_on_appliance() {
    local vm_ip
    local vm

    vm=$(xe vm-list name-label="$APPLIANCE_NAME" --minimal)

    [ -n "$vm" ]

    # Wait until appliance is accessible
    while ! ping -c 1 "${vm_ip:-}" > /dev/null 2>&1; do
        vm_ip=$(xe vm-param-get param-name=networks uuid=$vm | sed -e 's,^.*0/ip: ,,g' | sed -e 's,;.*$,,g')
        sleep 1
    done

    ssh \
        -q \
        -i /root/dom0key \
        -o UserKnownHostsFile=/dev/null \
        -o StrictHostKeyChecking=no \
        -o BatchMode=yes \
        "$DOMZERO_USER@$vm_ip" bash -e -u -s -x -- "$@"
}

function configure_networking() {
    local network_settings

    network_settings="$1"

    . "$network_settings"

    xe pif-introduce \
        device=eth0 host-uuid=$(xe host-list --minimal) mac=$MACADDRESS

    PIF=$(xe pif-list device=eth0 --minimal)
    HOST_INT_NET=$(xe network-list name-label="Host internal management network" --minimal)

    ORIGINAL_MGT_NET=$(xe pif-param-get param-name=network-uuid uuid=$PIF)
    NEW_MGT_NET=$(xe network-create name-label=mgt name-description=mgt)
    NEW_MGT_VLAN=$(xe vlan-create vlan=100 pif-uuid=$PIF network-uuid=$NEW_MGT_NET)
    NEW_PIF=$(xe pif-list VLAN=100 device=eth0 --minimal)
    VM=$(xe vm-list name-label="$APPLIANCE_NAME" --minimal)
    APP_IMPORTED_NOW="false"
    if [ -z "$VM" ]; then
        VM=$(xe vm-import filename=/mnt/ubuntu/root/staging_vm.xva)
        xe vm-param-set name-label="$APPLIANCE_NAME" uuid=$VM
        APP_IMPORTED_NOW="true"
    fi
    DNS_ADDRESSES=$(echo "$NAMESERVERS" | sed -e "s/,/ /g")

    xe pif-reconfigure-ip \
        uuid=$PIF \
        mode=static \
        IP=0.0.0.0 \
        netmask=0.0.0.0

    xe pif-reconfigure-ip \
        uuid=$NEW_PIF \
        mode=static \
        IP=192.168.33.2 \
        netmask=255.255.255.0 \
        gateway=192.168.33.1 \
        DNS=192.168.33.1

    xe host-management-reconfigure pif-uuid=$NEW_PIF

    # Purge all vifs of appliance
    IFS=,
    for vif in $(xe vif-list vm-uuid=$VM --minimal); do
        xe vif-destroy uuid=$vif
    done
    unset IFS

    # Create vifs for the appliance
    xe vif-create vm-uuid=$VM network-uuid=$HOST_INT_NET device=0
    xe vif-create vm-uuid=$VM network-uuid=$ORIGINAL_MGT_NET mac=$MACADDRESS device=1
    xe vif-create vm-uuid=$VM network-uuid=$NEW_MGT_NET device=2

    xe vm-start uuid=$VM

    # Wait until appliance is accessible
    while ! ping -c 1 "${VM_IP:-}" > /dev/null 2>&1; do
        VM_IP=$(xe vm-param-get param-name=networks uuid=$VM | sed -e 's,^.*0/ip: ,,g' | sed -e 's,;.*$,,g')
        sleep 1
    done

    if [ "$APP_IMPORTED_NOW" = "true" ]; then
        rm -f /root/dom0key
        rm -f /root/dom0key.pub
        ssh-keygen -f /root/dom0key -P "" -C "dom0"
        DOMID=$(xe vm-param-get param-name=dom-id uuid=$VM)

        # Authenticate temporary key to appliance
        xenstore-write /local/domain/$DOMID/authorized_keys/$DOMZERO_USER "$(cat /root/dom0key.pub)"
        xenstore-chmod -u /local/domain/$DOMID/authorized_keys/$DOMZERO_USER r$DOMID

        while ! echo "true" | bash_on_appliance; do
            echo "waiting for key to be activated"
            sleep 1
        done

        # Remove authorized_keys updater
        echo "echo \"\" | crontab -" | bash_on_appliance

        # Create an ssh key for domzero user
        echo "ssh-keygen -f /home/$DOMZERO_USER/.ssh/id_rsa -C $DOMZERO_USER@appliance -N \"\" -q" | bash_on_appliance
    fi

    # Update network configuration
    {
    cat << EOF
sudo tee /etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

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
    } | bash_on_appliance

    tmpdomzerokey=$(mktemp)

    # Enable domzero user to log in to dom0
    echo "cat /home/$DOMZERO_USER/.ssh/id_rsa.pub" | bash_on_appliance > $tmpdomzerokey

    # Update ssh keys and reboot, so settings applied
    {
        echo "sudo tee /root/.ssh/authorized_keys"
        cat /root/.ssh/authorized_keys
    } | bash_on_appliance

    echo "sudo reboot" | bash_on_appliance

    cat $tmpdomzerokey >> /root/.ssh/authorized_keys
}

function transfer_settings_to_appliance() {
    local network_settings

    network_settings="$1"

    configure_networking "$network_settings"
    /opt/xensource/libexec/interface-reconfigure rewrite
}

function dump_disk_config() {
    echo "DUMPING Primary disk's configuration"
    sfdisk -d /dev/xvda
}

main
