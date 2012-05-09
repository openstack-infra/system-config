class jenkins_jobs($site, $projects) {
  file { '/usr/local/jenkins_jobs':
    owner => 'root',
    group => 'root',
    mode => 755,
    ensure => 'directory',
    recurse => true,
    source => ['puppet:///modules/jenkins_jobs/']
  }

  jenkins_jobs::process_projects { $projects:
    site => $site,
    require => File['/usr/local/jenkins_jobs']
  }
}
