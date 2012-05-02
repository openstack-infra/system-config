define jenkins_jobs::generic_jobs($site, $project, $node_group, $ensure="present") {
  jenkins_jobs::jobs::docs { $name:
    site => $site,
    project => $project,
    node_group => $node_group,
    ensure => $ensure
  }

  jenkins_jobs::jobs::merge_check { $name:
    site => $site,
    project => $project,
    node_group => $node_group,
    trigger_branches => [[$project, '**']],
    ensure => $ensure
  }

  jenkins_jobs::jobs::merge_gate { $name:
    site => $site,
    project => $project,
    node_group => $node_group,
    trigger_branches => [[$project, '**']],
    ensure => $ensure
  }

  jenkins_jobs::jobs::ppa { $name:
    site => $site,
    project => $project,
    node_group => $node_group,
    ensure => $ensure
  }

  jenkins_jobs::jobs::tarball { $name:
    site => $site,
    project => $project,
    node_group => $node_group,
    upload_project => $project,
    trigger_branches => [[$project, '^(?!refs/).*$']],
    ensure => $ensure
  }

}
