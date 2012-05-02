define jenkins_jobs::jobs::python27_gate($site, $project, $node_group, $trigger_branches, $ensure="present") {
  jenkins_jobs::build_job { "gate-${name}-python27":
    ensure => $ensure,
    site => $site,
    project => $project,
    job => "python27",
    node_group => $node_group,
    triggers => trigger("gerrit_comment_plain"),
    builders => [builder("gerrit_git_prep"), builder("copy_bundle"), builder("python27")],
    trigger_branches => $trigger_branches,
    auth_build => true
  }
}
