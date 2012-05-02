define jenkins_jobs::jobs::tarball($site, $project, $node_group, $trigger_branches, $upload_project, $ensure="present") {
  jenkins_jobs::build_job { "${name}-tarball":
    ensure => $ensure,
    site => $site,
    project => $project,
    job => "tarball",
    upload_project => $upload_project,
    node_group => $node_group,
    triggers => trigger("gerrit_ref_updated"),
    builders => [builder("gerrit_git_prep"), builder("copy_bundle"), builder("tarball")],
    publishers => publisher("tarball"),
    trigger_branches => $trigger_branches
  }
}
