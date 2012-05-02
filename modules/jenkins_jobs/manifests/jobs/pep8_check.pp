define jenkins_jobs::jobs::pep8_check($site, $project, $node_group, $trigger_branches, $ensure="present") {
  jenkins_jobs::build_job { "check-${name}-pep8":
    ensure => $ensure,
    site => $site,
    project => $project,
    job => "pep8",
    node_group => $node_group,
    triggers => trigger("gerrit_uploaded_plain"),
    builders => [builder("gerrit_git_prep"), builder("copy_bundle"), builder("pep8")],
    publishers => publisher("pep8"),
    trigger_branches => $trigger_branches,
    auth_build => true
  }
}
