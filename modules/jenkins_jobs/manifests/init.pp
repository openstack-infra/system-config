class jenkins_jobs($site, $projects) {

  jenkins_jobs::add_jobs { $projects:
    site => "${site}"
  }

  exec { "jenkins":
    command => "curl https://jenkins.${site}.org/reload",
    refreshonly => true
  }
}
