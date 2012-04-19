define jenkins_jobs::generic_jobs($site, $project, $node_group) {
  jenkins_jobs::jobs::docs { $name:
    site => $site,
    project => $project,
    node_group => $node_group
  }

  jenkins_jobs::jobs::merge_gate { $name:
    site => $site,
    project => $project,
    node_group => $node_group,
    trigger_branches => [[$project, '**']]
  }

  jenkins_jobs::jobs::ppa { $name:
    site => $site,
    project => $project,
    node_group => $node_group
  }

  jenkins_jobs::jobs::tarball { $name:
    site => $site,
    project => $project,
    node_group => $node_group,
    trigger_branches => [[$project, '^(?!refs/).*$']]
  }

}
