define jenkins_jobs::jobs::python26_gate($site, $project, $node_group, $trigger_branches, $ensure="present") {
  jenkins_jobs::build_job { "gate-${name}-python26":
    ensure => $ensure,
    site => $site,
    project => $project,
    job => "python26",
    node_group => $node_group,
    triggers => trigger("gerrit_comment_plain"),
    builders => [builder("gerrit_git_prep"), builder("copy_bundle"), builder("python26")],
    trigger_branches => $trigger_branches,
    auth_build => true
  }
}
