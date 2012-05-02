define jenkins_jobs::jobs::ppa($site, $project, $node_group, $ensure="present") {
  jenkins_jobs::build_job { "${name}-ppa":
    ensure => $ensure,
    site => $site,
    project => $project,
    job => "ppa",
    node_group => $node_group,
    builders => builder("ppa"),
    publishers => publisher("ppa")
  }
}
