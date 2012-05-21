class jenkins_jobs($site, $projects) {
  package { 'python-yaml':
    ensure => 'present'
  }

  file { '/usr/local/jenkins_jobs':
    owner => 'root',
    group => 'root',
    mode => 755,
    ensure => 'directory',
    recurse => true,
    source => ['puppet:///modules/jenkins_jobs/'],
    require => Package['python-yaml']
  }

  file { '/usr/local/jenkins_jobs/jenkins_jobs.ini':
    owner => 'root',
    group => 'root',
    mode => 440,
    ensure => 'present',
    source => 'file:///root/secret-files/jenkins_jobs.ini',
    replace => 'true',
    require => File['/usr/local/jenkins_jobs']
  }

  process_projects { $projects:
    site => $site,
    require => File['/usr/local/jenkins_jobs/jenkins_jobs.ini']
  }
}
