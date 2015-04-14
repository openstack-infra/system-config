#!/bin/bash

ROOT=$(readlink -fn $(dirname $0)/..)
MODULE_PATH="${ROOT}/modules:/etc/puppet/modules"

export PUPPET_INTEGRATION_TEST=1

cat > clonemap.yaml <<EOF
clonemap:
  - name: openstack-infra/project-config
    dest: /etc/project-config
  - name: '(.*?)/puppet-(.*)'
    dest: '/etc/puppet/modules/\2'
EOF

# These arrays are initialized here and populated in modules.env

# Array of modules to be installed key:value is module:version.
declare -A MODULES

# Array of modues to be installed from source and without dependency resolution.
# key:value is source location, revision to checkout
declare -A SOURCE_MODULES

# Array of modues to be installed from source and without dependency resolution from openstack git
# key:value is source location, revision to checkout
declare -A INTEGRATION_MODULES


project_names=""
source ../modules.env
for MOD in ${!INTEGRATION_MODULES[*]}; do
    project_scope=$(basename `dirname $MOD`)
    repo_name=`basename $MOD`
    project_names+=" $project_scope/$repo_name"
done

sudo -E /usr/zuul-env/bin/zuul-cloner -m clonemap.yaml --cache-dir /opt/git \
    git://git.openstack.org \
    openstack-infra/project-config \
    $project_names


if [[ ! -d envassert ]] ; then
    mkdir envassert
fi


sudo puppet apply --modulepath=${MODULE_PATH} --color=false --verbose --debug -e 'include openstack_project::server'

echo "Set up localhost root ssh"

echo "" | sudo tee -a /etc/ssh/sshd_config
echo "Match address 127.0.0.1" | sudo tee -a /etc/ssh/sshd_config
echo "    PermitRootLogin without-password" | sudo tee -a /etc/ssh/sshd_config
echo "" | sudo tee -a /etc/ssh/sshd_config
echo "Match address ::1" | sudo tee -a /etc/ssh/sshd_config
echo "    PermitRootLogin without-password" | sudo tee -a /etc/ssh/sshd_config
mkdir -p .ssh
ssh-keygen -f ~/.ssh/id_rsa -b 2048 -C "beaker key" -P ""
sudo mkdir -p /root/.ssh
cat ~/.ssh/id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys
sudo service ssh restart

sudo pip install envassert

fab -H localhost check

