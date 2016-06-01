# Finglonger
class openstack_project::finglonger(
){


  vcsrepo { '/opt/finglonger':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://git.openstack.org/openstack-infra/finglonger',
  }


  file { '/opt/finglonger/.git/hooks/post-merge':
    owner   => root,
    group   => root,
    mode    => '0755',
    source  => 'puppet:///modules/openstack_project/finglonger-hook',
    require => Vcsrepo['/opt/finglonger'],
  }

}

