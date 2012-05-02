define jenkins_jobs::python_jobs($site, $project, $node_group, $ensure="present") {
  jenkins_jobs::jobs::coverage { $name:
    site => $site,
    project => $project,
    node_group => $node_group,
    ensure => $ensure
  }
  jenkins_jobs::jobs::pep8_gate { $name:
    site => $site,
    project => $project,
    node_group => $node_group,
    trigger_branches => [[$project, '**']],
    ensure => $ensure
  }
  jenkins_jobs::jobs::python26_gate { $name:
    site => $site,
    project => $project,
    node_group => $node_group,
    trigger_branches => [[$project, '**']],
    ensure => $ensure
  }
  jenkins_jobs::jobs::python27_gate { $name:
    site => $site,
    project => $project,
    node_group => $node_group,
    trigger_branches => [[$project, '**']],
    ensure => $ensure
  }
  jenkins_jobs::jobs::venv { $name:
    site => $site,
    project => $project,
    node_group => $node_group,
    ensure => $ensure
  }
}
