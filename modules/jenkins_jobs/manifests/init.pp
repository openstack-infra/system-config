class jenkins_jobs($site) {
  exec { "jenkins":
    command => "/usr/bin/curl https://jenkins.${site}.org/reload",
    refreshonly => true
  }
}
