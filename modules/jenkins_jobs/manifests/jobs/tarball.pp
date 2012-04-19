define jenkins_jobs::jobs::tarball($site, $project, $node_group, $trigger_branches) {
  jenkins_jobs::build_job { "${name}-tarball":
    site => $site,
    project => $project,
    job => "tarball",
    node_group => $node_group,
    triggers => trigger("gerrit_ref_updated"),
    builders => [builder("gerrit_git_prep"), builder("copy_bundle"), builder("tarball")],
    publishers => publisher("tarball"),
    trigger_branches => $trigger_branches
  }
}
