# == Class: openstack_project::npm_mirror
#
class openstack_project::npm_mirror (
  $uri_rewrite,
  $data_directory,
) {

  file { $data_directory:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
  }

  class { '::nodejs':
    repo_url_suffix => 'node_4.x',
  }

  # See: https://github.com/davglass/registry-static/pull/45
  package { 'patch-package-json':
    ensure   => '0.0.4',
    provider => 'npm',
    require  => Class['nodejs'],
  }

  package { 'follow-registry':
    ensure   => '2.0.0',
    provider => 'npm',
    require  => [
      Class['nodejs'],
    ]
  }

  # The registry mirroring script.
  package { 'registry-static':
    ensure   => '2.2.0',
    provider => 'npm',
    require  => [
      Class['nodejs'],
      Package['follow-registry'],
      Package['patch-package-json'],
    ]
  }

  # The afs-blob-store file structure rewriter.
  package { 'afs-blob-store':
    ensure   => '1.0.1',
    provider => 'npm',
    require  => [
      Class['nodejs'],
    ]
  }

  # Common registry hooks
  package { 'openstack-registry-hooks':
    ensure   => '1.1.0',
    provider => 'npm',
    require  => [
      Class['nodejs'],
    ]
  }
}
