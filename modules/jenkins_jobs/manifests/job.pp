define jenkins_jobs::job($site, $project, $job, $triggers="", $builders, $publishers="", $logrotate="", $scm="") {

  file { "/var/lib/jenkins/jobs/${project}-${job}":
    ensure => directory,
    owner => 'jenkins',
  }

  file { "/var/lib/jenkins/jobs/${project}-${job}/builds":
    ensure => directory,
    owner => 'jenkins',
    require => File["/var/lib/jenkins/jobs/${project}-${job}"]
  }

  file { "/var/lib/jenkins/jobs/${project}-${job}/config-history":
    ensure => directory,
    owner => 'jenkins',
    require => File["/var/lib/jenkins/jobs/${project}-${job}"]
  }

  file { "/var/lib/jenkins/jobs/${project}-${job}/config.xml":
    ensure => present,
    content => template("jenkins_jobs/body.xml.erb"),
    owner => 'jenkins',
    require => File["/var/lib/jenkins/jobs/${project}-${job}"],
    notify => Service["jenkins"]
  }

  file { "/var/lib/jenkins/jobs/${project}-${job}/nextBuildNumber":
    ensure => present,
    content => "1",
    owner => 'jenkins',
    replace => false,
    require => File["/var/lib/jenkins/jobs/${project}-${job}"]
  }

}
