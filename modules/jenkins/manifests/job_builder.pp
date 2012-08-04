class jenkins::job_builder($url, $username, $password, $site,
                           $projects_source, $template_source) {

  include pip

  package { 'python-yaml':
    ensure => 'present'
  }

  File {
      owner => 'root',
      group => 'root',
      mode  => 755
  }

  file { '/usr/local/jenkins_jobs':
    ensure => 'directory',
  }

  file { '/usr/local/jenkins_jobs/jenkins_jobs.py':
    ensure => present,
    source => 'puppet:///modules/jenkins/jenkins_jobs.py',
    require => [File['/usr/local/jenkins_jobs'],
                Package['python-yaml']],
  }

  file { '/usr/local/jenkins_jobs/modules':
    ensure => 'directory',
    recurse => true,
    source => 'puppet:///modules/jenkins/modules',
    require => File['/usr/local/jenkins_jobs/jenkins_jobs.py'],
    notify => Exec["jenkins_job_${site}"]
  }

  file { '/usr/local/jenkins_jobs/templates':
    ensure => 'directory',
    recurse => true,
    source => $templates_source,
    require => File['/usr/local/jenkins_jobs/jenkins_jobs.py'],
    notify => Exec["jenkins_job_${site}"]
  }

  file { '/usr/local/jenkins_jobs/projects':
    ensure => 'directory',
    recurse => true,
    source => $projects_source,
    require => File['/usr/local/jenkins_jobs/jenkins_jobs.py'],
    notify => Exec["jenkins_job_${site}"]
  }

  file { '/usr/local/jenkins_jobs/jenkins_jobs.ini':
    mode => 440,
    ensure => 'present',
    content => template('jenkins/jenkins_jobs.ini.erb'),
    replace => 'true',
    require => File['/usr/local/jenkins_jobs'],
    notify => Exec["jenkins_job_${site}"]
  }

  exec { "jenkins_job_${site}":
    command => "python /usr/local/jenkins_jobs/jenkins_jobs.py update /usr/local/jenkins_jobs/projects/${site}",
    cwd => '/usr/local/jenkins_jobs/',
    path => '/bin:/usr/bin',
    refreshonly => true,
    require => [
      File['/usr/local/jenkins_jobs/jenkins_jobs.ini'],
      File['/usr/local/jenkins_jobs/projects'],
      File['/usr/local/jenkins_jobs/templates'],
      Package['python-jenkins']
      ]
  }

  package { "python-jenkins":
    ensure => latest,  # okay to use latest for pip
    provider => pip,
    require => Class[pip]
  }

}
