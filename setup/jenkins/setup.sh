#!/usr/bin/env bash

set -ex

apt-get update

JENKINS=jenkins

# setup ~jenkins/.ssh
function ssh_setup() {
    SSH_CONFIG =<<EOF
UserKnownHostsFile=/dev/null
StrictHostKeyChecking=no

Host *.*
  UserKnownHostsFile=/dev/null
  StrictHostKeyChecking=no
EOF
    echo $SSH_CONFIG > ~$JENKINS/.ssh/config

    # Setup ssh keys id_rsa and id_rsa.pub in ~$JENKINS/.ssh/.
    chmod 600 ~$JENKINS/.ssh/id_rsa*
}

function flip_jenkins_job {
    # Download jenkins-cli.jar
    if [ ! -f /usr/local/bin/jenkins-cli.jar ]; then
        wget -O $HOME/jenkins-cli.jar https://jenkins.opencontrail.org/jnlpJars/jenkins-cli.jar --no-check-certificate
    fi
    java -jar $HOME/jenkins-cli.jar -s http://jenkins.opencontrail.org:8080 disable-job $1
    java -jar $HOME/jenkins-cli.jar -s http://jenkins.opencontrail.org:8080 enable-job $1
}

# setup ~jenkins/.gitconfig
function git_setup() {
    GIT_CONFIG=<<EOF
[user]
        name = Ananth Suryanarayana
        email = anantha@juniper.net
[core]
        editor = vim
        excludesfile = /home/ananth/.gitignore
[color]
        ui = auto
[branch]
        autosetuprebase = always
EOF

    echo $GIT_CONFIG > ~$JENKINS/.gitconfig
}

# Setup a node as a build system where contrail software can be built.
function build_setup {
    apt-get -y install python-software-properties git python-lxml unzip patch scons flex bison make vim ant libexpat-dev libgettextpo0 libcurl4-openssl-dev python-dev autoconf automake build-essential libtool libevent-dev libxml2-dev libxslt-dev python-setuptools build-essential devscripts debhelper ruby

    # Get repo tool from googleapis.com
    wget -O /usr/bin/repo http://commondatastorage.googleapis.com/git-repo-downloads/repo && chmd 755 /usr/bin/repo

    add-apt-repository -y ppa:webupd8team/java
    apt-get update
    echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
    echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections
    apt-get -y install oracle-java7-installer
}

sudo build_setup
git_setup
ssh_setup

