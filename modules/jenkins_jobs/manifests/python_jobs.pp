define jenkins_jobs::python_jobs($site, $assigned_nodes) {
  $project = $name

  job { "${name}-coverage":
    site => "${site}",
    project => "${name}",
    job => "coverage",
    assigned_nodes => $assigned_nodes,
    one_node => "true",
    logrotate => template("jenkins_jobs/logrotate.xml.erb"),
    builders => [template("jenkins_jobs/builder_copy_bundle.xml.erb"), template("jenkins_jobs/builder_coverage.xml.erb")],
    publishers => template("jenkins_jobs/publisher_coverage.xml.erb"),
    triggers => template("jenkins_jobs/trigger_timed_15mins.xml.erb"),
    scm => template("jenkins_jobs/scm_git.xml.erb")
  }

  job { "${name}-docs":
    site => "${site}",
    project => "${name}",
    job => "docs",
    assigned_nodes => $assigned_nodes,
    one_node => "true",
    triggers => template("jenkins_jobs/trigger_timed_15mins.xml.erb"),
    builders => [template("jenkins_jobs/builder_copy_bundle.xml.erb"), template("jenkins_jobs/builder_docs.xml.erb")],
    publishers => template("jenkins_jobs/publisher_docs.xml.erb"),
    scm => template("jenkins_jobs/scm_git.xml.erb")
  }

  job { "${name}-pep8":
    site => "${site}",
    project => "${name}",
    job => "pep8",
    assigned_nodes => $assigned_nodes,
    one_node => "false",
    triggers => template("jenkins_jobs/trigger_gerrit_comment.xml.erb"),
    builders => [template("jenkins_jobs/builder_gerrit_git_prep.xml.erb"), template("jenkins_jobs/builder_copy_bundle.xml.erb"), template("jenkins_jobs/builder_pep8.xml.erb")],
    publishers => template("jenkins_jobs/publisher_pep8.xml.erb")
  }

  job { "${name}-python26":
    site => "${site}",
    project => "${name}",
    job => "python26",
    assigned_nodes => $assigned_nodes,
    one_node => "false",
    triggers => template("jenkins_jobs/trigger_gerrit_comment.xml.erb"),
    builders => [template("jenkins_jobs/builder_gerrit_git_prep.xml.erb"), template("jenkins_jobs/builder_copy_bundle.xml.erb"), template("jenkins_jobs/builder_python26.xml.erb")],
  }

  job { "${name}-python27":
    site => "${site}",
    project => "${name}",
    job => "python27",
    assigned_nodes => $assigned_nodes,
    one_node => "false",
    triggers => template("jenkins_jobs/trigger_gerrit_comment.xml.erb"),
    builders => [template("jenkins_jobs/builder_gerrit_git_prep.xml.erb"), template("jenkins_jobs/builder_copy_bundle.xml.erb"), template("jenkins_jobs/builder_python27.xml.erb")],
  }

  job { "${name}-tarball":
    site => "${site}",
    project => "${name}",
    job => "tarball",
    assigned_nodes => $assigned_nodes,
    one_node => "true",
    triggers => template("jenkins_jobs/trigger_gerrit_ref_updated.xml.erb"),
    builders => [template("jenkins_jobs/builder_gerrit_git_prep.xml.erb"), template("jenkins_jobs/builder_copy_bundle.xml.erb"), template("jenkins_jobs/builder_tarball.xml.erb")],
    publishers => template("jenkins_jobs/publisher_tarball.xml.erb")
  }

  job { "${name}-venv":
    site => "${site}",
    project => "${name}",
    job => "venv",
    assigned_nodes => $assigned_nodes,
    one_node => "true",
    triggers => template("jenkins_jobs/trigger_timed_midnight.xml.erb"),
    builders => template("jenkins_jobs/builder_venv.xml.erb"),
    publishers => template("jenkins_jobs/publisher_venv.xml.erb"),
    scm => template("jenkins_jobs/scm_git.xml.erb")
  }

}
