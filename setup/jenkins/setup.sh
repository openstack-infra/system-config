#!/usr/bin/env bash

# Setup ssh keys id_rsa and id_rsa.pub in ~jenkins/.ssh/.

# Setup ~jenkins/.ssh/config
SSH_CONFIG =<<EOF
UserKnownHostsFile=/dev/null
StrictHostKeyChecking=no

Host *.*
  UserKnownHostsFile=/dev/null
  StrictHostKeyChecking=no
EOF

echo $SSH_CONFIG > ~jenkins/.ssh/config

function flip_jenkins_job() {
    # Download jenkins-cli.jar
    wget "https://jenkins.opencontrail.org/jnlpJars/jenkins-cli.jar" --no-check-certificate
    java -jar jenkins-cli.jar -s http://jenkins.opencontrail.org:8080 disable-job $1
    java -jar jenkins-cli.jar -s http://jenkins.opencontrail.org:8080 enable-job $1
}

# setup ~jenkins/.gitconfig
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

echo $GIT_CONFIG > ~jenkins/.gitconfig

function build_setup {
    apt-get -y install python-software-properties

    apt-get -y install git python-lxml unzip patch scons flex bison make vim ant libexpat-dev libgettextpo0 libcurl4-openssl-dev python-dev autoconf automake build-essential libtool libevent-dev libxml2-dev libxslt-dev python-setuptools build-essential devscripts debhelper

    wget -O /usr/local/bin/repo http://commondatastorage.googleapis.com/git-repo-downloads/repo
    chmd 755 /usr/local/bin/repo

    add-apt-repository -y ppa:webupd8team/java
    apt-get update
    echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
    echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections
    apt-get -y install oracle-java7-installer
}

