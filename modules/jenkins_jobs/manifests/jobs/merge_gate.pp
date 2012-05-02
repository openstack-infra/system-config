define jenkins_jobs::jobs::merge_gate($site, $project, $node_group, $trigger_branches, $ensure="present") {
  jenkins_jobs::build_job { "gate-${name}-merge":
    ensure => $ensure,
    site => $site,
    project => $project,
    job => "merge",
    node_group => $node_group,
    triggers => trigger("gerrit_comment"),
    builders => builder("gerrit_git_prep"),
    trigger_branches => $trigger_branches,
    auth_build => true
  }
}
