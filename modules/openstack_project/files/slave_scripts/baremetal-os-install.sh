#!/bin/bash -xe

set -x
sudo cobbler sync
sudo cobbler system edit --netboot-enabled=Y --name=baremetal1
sudo cobbler system edit --netboot-enabled=Y --name=baremetal2
sudo cobbler system edit --netboot-enabled=Y --name=baremetal3
sudo cobbler system edit --netboot-enabled=Y --name=baremetal4
sudo cobbler system edit --netboot-enabled=Y --name=baremetal5
sudo cobbler system edit --netboot-enabled=Y --name=baremetal6
sudo cobbler system edit --netboot-enabled=Y --name=baremetal7
sudo cobbler system edit --netboot-enabled=Y --name=baremetal8
sudo cobbler system edit --netboot-enabled=Y --name=baremetal9
sudo cobbler system reboot --name=baremetal1
sudo cobbler system reboot --name=baremetal2
sudo cobbler system reboot --name=baremetal3
sudo cobbler system reboot --name=baremetal4
sudo cobbler system reboot --name=baremetal5
sudo cobbler system reboot --name=baremetal6
sudo cobbler system reboot --name=baremetal7
sudo cobbler system reboot --name=baremetal8
sudo cobbler system reboot --name=baremetal9
