define jenkins_jobs::jobs::merge_gate($site, $project, $node_group, $trigger_branches) {
  jenkins_jobs::build_job { "gate-${name}-merge":
    site => $site,
    project => $project,
    job => "merge",
    node_group => $node_group,
    triggers => trigger("gerrit_comment"),
    builders => builder("gerrit_git_prep"),
    trigger_branches => $trigger_branches
  }
}
