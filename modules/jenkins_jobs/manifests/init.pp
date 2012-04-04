class jenkins_jobs($site, $projects, $type, $assigned_nodes) {

  service { "jenkins":
    ensure => running
  }

  jenkins_jobs::generic_jobs { $projects:
    site => "${site}",
    assigned_nodes => $assigned_nodes
  }


  case $type {
    python: {
      jenkins_jobs::python_jobs { $projects:
        site => "${site}",
        assigned_nodes => $assigned_nodes
      }
    }
    default: {
      fail("Unknown job type '${type}' specified")
    }
  }

}
