define jenkins_jobs::jobs::venv($site, $project, $node_group) {
  jenkins_jobs::build_job { "${name}-venv":
    site => $site,
    project => $project,
    job => "venv",
    node_group => $node_group,
    triggers => trigger("timed_midnight"),
    builders => builder("venv"),
    publishers => publisher("venv"),
    scm => scm("git")
  }
}
