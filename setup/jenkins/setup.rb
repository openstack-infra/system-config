#!/usr/bin/env ruby

`apt-get -y install scons`

# Setup ssh keys id_rsa and id_rsa.pub in ~jenkins/.ssh/., ~root/.ssh/.

def flip_jenkins_job(job = "gate-contrail-controller-build")
    # Download jenkins-cli.jar
    `wget "https://jenkins.opencontrail.org/jnlpJars/jenkins-cli.jar" --no-check-certificate`
    `java -jar jenkins-cli.jar -s http://jenkins.opencontrail.org:8080 disable-job #{job}`
    `java -jar jenkins-cli.jar -s http://jenkins.opencontrail.org:8080 enable-job #{job}`
end

