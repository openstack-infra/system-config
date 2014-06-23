#!/usr/bin/env ruby

$LOAD_PATH.unshift "/usr/local/jenkins/slave_scripts/",
                   "/usr/local/jenkins/slave_scripts/ci-infra"

require 'util'

o, e = Sh.rrun("java -jar /root/jenkins-cli.jar -s http://jenkins.opencontrail.org:8080 list-jobs")
o.split(/\r\n/).each { |job|
    puts job
}

#Sh.rrun("java -jar /root/jenkins-cli.jar -s http://jenkins.opencontrail.org:8080 list-jobs | \grep -v "Contrail Neutron" | xargs -n 1 java -jar /root/jenkins-cli.jar -s http://jenkins.opencontrail.org:8080 disable-job && java -jar /root/jenkins-cli.jar -s http://jenkins.opencontrail.org:8080 list-jobs | \grep -v "Contrail Neutron" | xargs -n 1 java -jar /root/jenkins-cli.jar -s http://jenkins.opencontrail.org:8080 enable-job

