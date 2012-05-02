define jenkins_jobs::jobs::coverage($site, $project, $node_group, $ensure="present") {
  jenkins_jobs::build_job { "${name}-coverage":
    ensure => $ensure,
    site => $site,
    project => $project,
    job => "coverage",
    node_group => $node_group,
    logrotate => misc("logrotate"),
    builders => [builder("copy_bundle"), builder("coverage")],
    publishers => publisher("coverage"),
    triggers => trigger("timed_15mins"),
    scm => scm("git")
  }
}
