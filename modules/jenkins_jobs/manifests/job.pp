define jenkins_jobs::job($site, $project, $job) {

  file { "/var/lib/jenkins/jobs/${project}-${job}":
    ensure => directory,
    owner => 'jenkins',
    group => 'nogroup'
  }

  file { "/var/lib/jenkins/jobs/${project}-${job}/builds":
    ensure => directory,
    owner => 'jenkins',
    group => 'nogroup',
    require => File["/var/lib/jenkins/jobs/${project}-${job}"],
    notify => Service["jenkins"]
  }

  file { "/var/lib/jenkins/jobs/${project}-${job}/config-history":
    ensure => directory,
    owner => 'jenkins',
    group => 'nogroup',
    require => File["/var/lib/jenkins/jobs/${project}-${job}"],
    notify => Service["jenkins"]
  }

  file { "/var/lib/jenkins/jobs/${project}-${job}/config.xml":
    ensure => present,
    content => template("jenkins_jobs/${job}.xml.erb"),
    owner => 'jenkins',
    group => 'nogroup',
    require => File["/var/lib/jenkins/jobs/${project}-${job}"],
    notify => Service["jenkins"]
  }

  file { "/var/lib/jenkins/jobs/${project}-${job}/nextBuildNumer":
    ensure => present,
    content => "1",
    owner => 'jenkins',
    group => 'nogroup',
    replace => false,
    require => File["/var/lib/jenkins/jobs/${project}-${job}"],
    notify => Service["jenkins"]
  }

}
