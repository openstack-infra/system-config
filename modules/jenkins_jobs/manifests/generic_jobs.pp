define jenkins_jobs::generic_jobs($site, $assigned_nodes) {
  $project = $name

  job { "${name}-merge":
    site => "${site}",
    project => "${name}",
    job => "merge",
    assigned_nodes => $assigned_nodes,
    one_node => "true",
    triggers => template("jenkins_jobs/trigger_gerrit_comment.xml.erb"),
    builders => template("jenkins_jobs/builder_gerrit_git_prep.xml.erb")
  }

  job { "${name}-ppa":
    site => "${site}",
    project => "${name}",
    job => "ppa",
    assigned_nodes => $assigned_nodes,
    one_node => "true",
    builders => template("jenkins_jobs/builder_ppa.xml.erb"),
    publishers => template("jenkins_jobs/publisher_ppa.xml.erb")
  }
}
