# == Class: infra_vars
#
class infra_vars (
  $gerrit_site,
  $git_site,
  $git_protocol,
  $pypi_mirror,
) {

  file { '/etc/infra':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/etc/infra/vars.sh':
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('infra_vars/vars.sh.erb'),
    require => File['/etc/infra'],
  }

  file { '/etc/infra/vars.yaml':
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('infra_vars/vars.yaml.erb'),
    require => File['/etc/infra'],
  }
}
