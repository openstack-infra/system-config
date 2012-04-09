define jenkins_jobs::add_jobs($site) {
  $project = $name

  jenkins_jobs::job { "${name}-coverage":
    site => "${site}",
    project => "${name}",
    job => "coverage",
    logrotate => template("jenkins_jobs/logrotate.xml.erb"),
    builders => [template("jenkins_jobs/builder_copy_bundle.xml.erb"), template("jenkins_jobs/builder_coverage.xml.erb")],
    publishers => template("jenkins_jobs/publisher_coverage.xml.erb"),
    triggers => template("jenkins_jobs/trigger_timed_15mins.xml.erb"),
    scm => template("jenkins_jobs/scm_git.xml.erb")
  }

  jenkins_jobs::job { "${name}-docs":
    site => "${site}",
    project => "${name}",
    job => "docs",
    triggers => template("jenkins_jobs/trigger_timed_15mins.xml.erb"),
    builders => [template("jenkins_jobs/builder_copy_bundle.xml.erb"), template("jenkins_jobs/builder_docs.xml.erb")],
    publishers => template("jenkins_jobs/publisher_docs.xml.erb"),
    scm => template("jenkins_jobs/scm_git.xml.erb")
  }

  jenkins_jobs::job { "gate-${name}-merge":
    site => "${site}",
    project => "${name}",
    job => "merge",
    triggers => template("jenkins_jobs/trigger_gerrit_comment.xml.erb"),
    builders => template("jenkins_jobs/builder_gerrit_git_prep.xml.erb")
  }

  jenkins_jobs::job { "gate-${name}-pep8":
    site => "${site}",
    project => "${name}",
    job => "pep8",
    triggers => template("jenkins_jobs/trigger_gerrit_comment.xml.erb"),
    builders => [template("jenkins_jobs/builder_gerrit_git_prep.xml.erb"), template("jenkins_jobs/builder_copy_bundle.xml.erb"), template("jenkins_jobs/builder_pep8.xml.erb")],
    publishers => template("jenkins_jobs/publisher_pep8.xml.erb")
  }

  jenkins_jobs::job { "${name}-ppa":
    site => "${site}",
    project => "${name}",
    job => "ppa",
    builders => template("jenkins_jobs/builder_ppa.xml.erb"),
    publishers => template("jenkins_jobs/publisher_ppa.xml.erb")
  }

  jenkins_jobs::job { "gate-${name}-python26":
    site => "${site}",
    project => "${name}",
    job => "python26",
    triggers => template("jenkins_jobs/trigger_gerrit_comment.xml.erb"),
    builders => [template("jenkins_jobs/builder_gerrit_git_prep.xml.erb"), template("jenkins_jobs/builder_copy_bundle.xml.erb"), template("jenkins_jobs/builder_python26.xml.erb")],
  }

  jenkins_jobs::job { "gate-${name}-python27":
    site => "${site}",
    project => "${name}",
    job => "python27",
    triggers => template("jenkins_jobs/trigger_gerrit_comment.xml.erb"),
    builders => [template("jenkins_jobs/builder_gerrit_git_prep.xml.erb"), template("jenkins_jobs/builder_copy_bundle.xml.erb"), template("jenkins_jobs/builder_python27.xml.erb")],
  }

  jenkins_jobs::job { "${name}-tarball":
    site => "${site}",
    project => "${name}",
    job => "tarball",
    triggers => template("jenkins_jobs/trigger_gerrit_ref_updated.xml.erb"),
    builders => [template("jenkins_jobs/builder_gerrit_git_prep.xml.erb"), template("jenkins_jobs/builder_copy_bundle.xml.erb"), template("jenkins_jobs/builder_tarball.xml.erb")],
    publishers => template("jenkins_jobs/publisher_tarball.xml.erb")
  }

  jenkins_jobs::job { "${name}-venv":
    site => "${site}",
    project => "${name}",
    job => "venv",
    triggers => template("jenkins_jobs/trigger_timed_midnight.xml.erb"),
    builders => template("jenkins_jobs/builder_venv.xml.erb"),
    publishers => template("jenkins_jobs/publisher_venv.xml.erb"),
    scm => template("jenkins_jobs/scm_git.xml.erb")
  }

}
