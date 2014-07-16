# == Class: turbo_hipster::cookbooks_ci
#
class turbo_hipster::noop_ci (
) {

  file { '/etc/turbo-hipster/scripts':
    ensure  => directory,
    require => File['/etc/turbo-hipster'],
  }

  file { '/etc/turbo-hipster/scripts/noop.sh':
    ensure  => present,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    require => File['/etc/turbo-hipster/scripts'],
    source  => 'puppet:///modules/turbo_hipster/noop_ci/noop_ci.sh',
  }

  file { '/etc/turbo-hipster/scripts/run-job.sh':
    ensure  => present,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    require => File['/etc/turbo-hipster/scripts'],
    source  => 'puppet:///modules/turbo_hipster/noop_ci/run-job.sh',
  }

  file { '/etc/turbo-hipster/conf.d/noop_ci.yaml':
    ensure  => present,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    require => File['/etc/turbo-hipster/conf.d'],
    source  => 'puppet:///modules/turbo_hipster/noop_ci/noop_ci.yaml',
  }
}
