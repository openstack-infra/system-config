#!/bin/bash -ux

# Copyright 2015 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

function puppet_version {
    # Default to 3 for the cases, like bridge, where there is no puppet
    (PATH=/opt/puppetlabs/bin:$PATH puppet --version || echo 3) | cut -d '.' -f 1
}
export PUPPET_VERSION=$(puppet_version)

if [ "$PUPPET_VERSION" == "3" ] ; then
    export MODULE_PATH=/etc/puppet/modules
elif [ "$PUPPET_VERSION" == "4" ] ; then
    export MODULE_PATH=/etc/puppetlabs/code/modules
fi

file=$1
fileout=`pwd`/${file}.out
ansible_root=`mktemp -d`
cat > $ansible_root/ansible.cfg <<EOF
[defaults]
local_tmp=$ansible_root/local_tmp
remote_tmp=$ansible_root/remote_tmp
log_path=$fileout
EOF
cat > $ansible_root/hosts <<EOF
localhost ansible_connection=local
[puppet]
localhost
EOF
echo "##" > $fileout
cat $file > $fileout
export ANSIBLE_CONFIG=$ansible_root/ansible.cfg
sudo -H -E /tmp/apply-ansible-env/bin/ansible-playbook -i $ansible_root/hosts -f1 playbooks/remote_puppet_adhoc.yaml -e puppet_environment=production -e manifest=`pwd`/$file -e puppet_noop=true -e puppet_logdest=$fileout -e mgmt_puppet_module_dir=$MODULE_PATH
ret=$?
if [ $ret -ne 0 ]; then
    mv $fileout $fileout.FAILED
fi
rm -fr $ansible_root
exit $ret
