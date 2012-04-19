define jenkins_jobs::build_job($site, $project, $job, $node_group, $triggers="", $builders, $publishers="", $logrotate="", $scm="", $trigger_branches="") {

  file { "/var/lib/jenkins/jobs/${name}":
    ensure => directory,
    owner => 'jenkins',
  }

  file { "/var/lib/jenkins/jobs/${name}/builds":
    ensure => directory,
    owner => 'jenkins',
    require => File["/var/lib/jenkins/jobs/${name}"]
  }

  file { "/var/lib/jenkins/jobs/${name}/config-history":
    ensure => directory,
    owner => 'jenkins',
    require => File["/var/lib/jenkins/jobs/${name}"]
  }

  file { "/var/lib/jenkins/jobs/${name}/config.xml":
    ensure => present,
    content => template("jenkins_jobs/body.xml.erb"),
    owner => 'jenkins',
    require => File["/var/lib/jenkins/jobs/${name}"],
    notify => Exec["jenkins"]
  }

  file { "/var/lib/jenkins/jobs/${name}/nextBuildNumber":
    ensure => present,
    content => "1",
    owner => 'jenkins',
    replace => false,
    require => File["/var/lib/jenkins/jobs/${name}"]
  }

}
