class jenkins_jobs($site, $projects) {

  service { "jenkins":
    ensure => running
  }

  jenkins_jobs::add_jobs { $projects:
    site => "${site}"
  }
}
