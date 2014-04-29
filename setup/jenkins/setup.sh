#!/usr/bin/env bash

set -ex

apt-get update

JENKINS=jenkins

# Setup jenkins ssh server port to 6000 and jnlp slave port to 6001

function iptables_restart {
/etc/init.d/iptables-persistent restart
}

function setup_nat_entries {
iptables -t nat -I PREROUTING -p tcp -d 148.251.46.180 --dport 8080 -j DNAT --to-destination 192.168.1.13:8080
iptables -t nat -I PREROUTING -p tcp -d 148.251.46.180 --dport 6000 -j DNAT --to-destination 192.168.1.13:6000
iptables -t nat -I PREROUTING -p tcp -d 148.251.46.180 --dport 6001 -j DNAT --to-destination 192.168.1.13:6001
iptables -I FORWARD -m state -d 192.168.1.0/24 --state NEW,RELATED,ESTABLISHED -j ACCEPT        
}

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
    wget "http://maven.jenkins-ci.org/content/repositories/releases/org/jenkins-ci/plugins/swarm-client/1.15/swarm-client-1.15-jar-with-dependencies.jar"
fi
java -jar $HOME/jenkins-cli.jar -s http://jenkins.opencontrail.org:8080 disable-job $1
java -jar $HOME/jenkins-cli.jar -s http://jenkins.opencontrail.org:8080 enable-job $1
}

# setup ~jenkins/.gitconfig
function git_setup() {
GIT_CONFIG=<<EOF
[user]
        name = OpenContrail CI
        email = ci-admin@opencontrail.org
[core]
        editor = vi
[color]
        ui = auto
[branch]
        autosetuprebase = always
EOF

echo $GIT_CONFIG > ~$JENKINS/.gitconfig
}

# Setup a node as a build system where contrail software can be built.
function build_setup {
apt-get -y install python-software-properties git python-lxml unzip patch scons flex bison make vim ant libexpat-dev libgettextpo0 libcurl4-openssl-dev python-dev autoconf automake build-essential libtool libevent-dev libxml2-dev libxslt-dev python-setuptools build-essential devscripts debhelper ruby maven traceroute wireshark

wget -O /usr/bin/repo http://commondatastorage.googleapis.com/git-repo-downloads/repo && chmod 755 /usr/bin/repo

add-apt-repository -y ppa:webupd8team/java
apt-get update
echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections
apt-get -y install oracle-java7-installer

useradd -m jenkins
# setup ~jenkins/.ssh

# test
ssh git@github.com

}

functions setup_certificates {
cp ~/.ssh/id_rsa server.key.orig
cp ~/.ssh/id_rsa server.key
cp ~/.ssh/id_rsa.pub server.key.pub

openssl req -new -key server.key -out server.csr
openssl rsa -in server.key.orig -out server.key
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt

# To install self-signed certificatie, do this
apt-get install ca-certificates
mkdir -p /usr/share/ca-certificates/jenkins
cp server.crt /usr/share/ca-certificates/jenkins/.
dpkg-reconfigure ca-certificates
# Say yes
}

functions start_slave {
# Install certificates
# setup_certificates

# Download slave.jar
# wget -O $HOME/slave.jar https://jenkins.opencontrail.org/jnlpJars/slave.jar
# java -jar slave.jar -jnlpUrl https://jenkins.opencontrail.org/computer/jnpr-slave-1/slave-agent.jnlp -jnlpCredentials ci-admin:b8057c342d448
java -jar swarm-client-1.15-jar-with-dependencies.jar -labels juniper-tests -mode normal -master http://jenkins.opencontrail.org:8080/ -fsroot ~jenkins -username ci-admin -password b8057c342d44883f750d93f1cc2d092f
}

sudo build_setup
git_setup
ssh_setup

