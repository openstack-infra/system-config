# == Class: openstack_project::trystack
#
class openstack_project::trystack (
  $vhost_name = $::fqdn,
) {
  include ::apache

  apache::vhost { $vhost_name:
    port     => 80,
    priority => '50',
    docroot  => '/opt/trystack',
    template => 'openstack_project/trystack.vhost.erb',
    require  => Vcsrepo['/opt/trystack'],
  }

  vcsrepo { '/opt/trystack':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://github.com/trystack/trystack_org_webcontents.git',
  }
}
