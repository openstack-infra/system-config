#!/usr/bin/env ruby

`apt-get -y install scons python-lxml unzip make`

# Setup ssh keys id_rsa and id_rsa.pub in ~jenkins/.ssh/., ~root/.ssh/.
# Setup ~jenkins/.ssh/config
SSH_CONFIG =<<EOF
UserKnownHostsFile=/dev/null
StrictHostKeyChecking=no

Host *.*
  UserKnownHostsFile=/dev/null
  StrictHostKeyChecking=no
EOF

def flip_jenkins_job(job = "gate-contrail-controller-build")
    # Download jenkins-cli.jar
    `wget "https://jenkins.opencontrail.org/jnlpJars/jenkins-cli.jar" --no-check-certificate`
    `java -jar jenkins-cli.jar -s http://jenkins.opencontrail.org:8080 disable-job #{job}`
    `java -jar jenkins-cli.jar -s http://jenkins.opencontrail.org:8080 enable-job #{job}`
end

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
