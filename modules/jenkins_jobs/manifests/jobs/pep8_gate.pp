define jenkins_jobs::jobs::pep8_gate($site, $project, $node_group, $trigger_branches) {
  jenkins_jobs::build_job { "gate-${name}-pep8":
    site => $site,
    project => $project,
    job => "pep8",
    node_group => $node_group,
    triggers => trigger("gerrit_comment"),
    builders => [builder("gerrit_git_prep"), builder("copy_bundle"), builder("pep8")],
    publishers => publisher("pep8"),
    trigger_branches => $trigger_branches
  }
}
