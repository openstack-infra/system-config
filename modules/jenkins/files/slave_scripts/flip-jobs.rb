#!/usr/bin/env ruby

$LOAD_PATH.unshift "/usr/local/jenkins/slave_scripts/",
                   "/usr/local/jenkins/slave_scripts/ci-infra"

require 'util'

CLI="java -jar /root/jenkins-cli.jar -s http://jenkins.opencontrail.org:8080"

o, e = Sh.rrun("#{CLI} list-jobs")
o.split(/\r\n/).each { |job|
    next if job !~ /ci-contrail/
    Sh.run("#{CLI} disable-job #{job}")
    sleep 2
    Sh.run("#{CLI} enable-job #{job}")
}
