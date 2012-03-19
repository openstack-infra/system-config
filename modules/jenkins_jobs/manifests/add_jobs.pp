define jenkins_jobs::add_jobs($site) {
  jenkins_jobs::job { "${name}-coverage":
    site => "${site}",
    project => "${name}",
    job => "coverage"
  }

  jenkins_jobs::job { "${name}-docs":
    site => "${site}",
    project => "${name}",
    job => "docs"
  }

  jenkins_jobs::job { "${name}-merge":
    site => "${site}",
    project => "${name}",
    job => "merge"
  }

  jenkins_jobs::job { "${name}-pep8":
    site => "${site}",
    project => "${name}",
    job => "pep8"
  }

  jenkins_jobs::job { "${name}-ppa":
    site => "${site}",
    project => "${name}",
    job => "ppa"
  }

  jenkins_jobs::job { "${name}-python26":
    site => "${site}",
    project => "${name}",
    job => "python26"
  }

  jenkins_jobs::job { "${name}-python27":
    site => "${site}",
    project => "${name}",
    job => "python27"
  }

  jenkins_jobs::job { "${name}-tarball":
    site => "${site}",
    project => "${name}",
    job => "tarball"
  }

  jenkins_jobs::job { "${name}-venv":
    site => "${site}",
    project => "${name}",
    job => "venv"
  }

}
