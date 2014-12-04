#! /usr/bin/env bash

# Sets up a log server for Jenkins to save test results to.

set -e

if [[ -z $DOMAIN ]]; then
    echo "ERROR: Please set your domain (e.g. mydomain.com) in the DOMAIN environment variable before running this script."
    exit 1
fi

if [[ -z $JENKINS_SSH_PUBLIC_KEY ]]; then
    echo "ERROR: Please set the path of your Jenkins SSH public key in the JENKINS_SSH_PUBLIC_KEY environment variable before running this script."
    exit 1
elif [[ ! -e  $JENKINS_SSH_PUBLIC_KEY ]]; then
    echo "ERROR: Could not find JENKINS_SSH_PUBLIC_KEY located here: '$JENKINS_SSH_PUBLIC_KEY'"
    exit 1
fi

PUPPET_MODULE_PATH="--modulepath=../modules:/etc/puppet/modules"

#It is assumed that this puppet script has already been run
#sudo bash -xe ../install_puppet.sh

#It is assumed that the system-config modules have already been installed
#sudo bash ../install_modules.sh

CLASS_ARGS="domain => '$DOMAIN',
            jenkins_ssh_key => '$(cat $JENKINS_SSH_PUBLIC_KEY | cut -d ' ' -f 2)', "


sudo puppet apply --verbose $PUPPET_MODULE_PATH -e "class {'openstack_project::log_server': $CLASS_ARGS }"
