define jenkins_jobs::jobs::docs($site, $project, $node_group, $ensure="present") {
  jenkins_jobs::build_job { "${name}-docs":
    ensure => $ensure,
    site => $site,
    project => $project,
    job => "docs",
    node_group => $node_group,
    triggers => trigger("timed_15mins"),
    builders => [builder("copy_bundle"), builder("docs")],
    publishers => publisher("docs"),
    scm => scm("git")
  }
}
