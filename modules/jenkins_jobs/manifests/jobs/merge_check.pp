define jenkins_jobs::jobs::merge_check($site, $project, $node_group, $trigger_branches, $ensure="present") {
  jenkins_jobs::build_job { "check-${name}-merge":
    ensure => $ensure,
    site => $site,
    project => $project,
    job => "merge",
    node_group => $node_group,
    triggers => trigger("gerrit_uploaded_merge"),
    builders => builder("gerrit_git_prep"),
    trigger_branches => $trigger_branches,
    auth_build => true
  }
}
