class jenkins_jobs($site, $projects) {

  service { "jenkins":
    ensure => running
  }

  jenkins_jobs::job { "copy-bundle":
    site => "${site}",
    project => "template",
    job => "copy-bundle"
  }

  jenkins_jobs::job { "gerrit-git-prep":
    site => "${site}",
    project => "template",
    job => "gerrit-git-prep"
  }

  jenkins_jobs::add_jobs { $projects:
    site => "${site}"
  }
}
