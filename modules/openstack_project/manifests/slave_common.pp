# == Class: openstack_project::slave_common
#
# Common configuration between openstack_project::slave and
# openstack_project::single_use_slave
class openstack_project::slave_common(
  $sudo         = false,
){
  file { '/home/jenkins/.pydistutils.cfg':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0644',
    source  => 'puppet:///modules/openstack_project/pydistutils.cfg',
    require => Class['jenkins::jenkinsuser'],
  }

  if ($sudo == true) {
    file { '/etc/sudoers.d/jenkins-sudo':
      ensure => present,
      source => 'puppet:///modules/openstack_project/jenkins-sudo.sudo',
      owner  => 'root',
      group  => 'root',
      mode   => '0440',
    }
  }

  file { '/etc/sudoers.d/jenkins-sudo-grep':
    ensure => present,
    source => 'puppet:///modules/openstack_project/jenkins-sudo-grep.sudo',
    owner  => 'root',
    group  => 'root',
    mode   => '0440',
  }

  vcsrepo { '/opt/zuul':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://git.openstack.org/openstack-infra/zuul.git',
  }

  python::virtualenv { '/usr/zuul-env':
    ensure       => present,
    owner        => 'root',
    group        => 'root',
    timeout      => 0,
  }

  exec { 'zuul-env-update':
    command     => '/usr/zuul-env/bin/pip --log /usr/zuul-env/pip.log install /opt/zuul',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/zuul'],
    require     => Python::Virtualenv['/usr/zuul-env'],
  }
}
