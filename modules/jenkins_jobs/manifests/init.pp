class jenkins_jobs($url, $username, $password, $site) {

  include pip

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
    content => template('jenkins_jobs/jenkins_jobs.ini.erb'),
    replace => 'true',
    require => File['/usr/local/jenkins_jobs']
  }

  exec { "jenkins_job_${site}":
    command => "python /usr/local/jenkins_jobs/jenkins_jobs.py update /usr/local/jenkins_jobs/projects/${site}",
    cwd => '/usr/local/jenkins_jobs/',
    path => '/bin:/usr/bin',
    require => [
      File['/usr/local/jenkins_jobs/jenkins_jobs.ini'],
      Package['python-jenkins']
      ]
  }

  package { "python-jenkins":
    ensure => latest,  # okay to use latest for pip
    provider => pip,
    require => Class[pip]
  }

}
