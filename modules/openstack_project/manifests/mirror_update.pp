# == Class: openstack_project::mirror_update
#
class openstack_project::mirror_update (
  $sysadmins = [],
  $bandersnatch_keytab = '',
  $reprepro_keytab = '',
  $admin_keytab = '',
  $gem_keytab = '',
  $npm_keytab = '',
  $centos_keytab = '',
  $epel_keytab = '',
  $fedora_keytab = '',
  $opensuse_keytab = '',
) {
  include ::gnupg
  include ::openstack_project::reprepro_mirror

  class { 'openstack_project::server':
    sysadmins => $sysadmins,
    afs       => true,
  }

  $data_directory = '/afs/.openstack.org/mirror/npm'
  $uri_rewrite    = 'localhost'
  class { 'openstack_project::npm_mirror':
    data_directory => $data_directory,
    uri_rewrite    => $uri_rewrite,
  }

  class { 'openstack_project::gem_mirror': }

  class { 'bandersnatch': }

  class { 'bandersnatch::mirror':
    mirror_root => '/afs/.openstack.org/mirror/pypi',
    static_root => '/afs/.openstack.org/mirror',
    hash_index  => true,
    require     => Class['bandersnatch'],
  }

  file { '/etc/bandersnatch.keytab':
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => $bandersnatch_keytab,
  }

  file { '/etc/gem.keytab':
    owner   => 'rubygems',
    group   => 'root',
    mode    => '0400',
    content => $gem_keytab,
    require  => Class['openstack_project::gem_mirror'],
  }

  file { '/etc/npm.keytab':
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => $npm_keytab,
  }

  file { '/etc/afsadmin.keytab':
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => $admin_keytab,
  }

  file { '/usr/local/bin/bandersnatch-mirror-update':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/openstack_project/bandersnatch-mirror-update.sh',
  }

  file { '/usr/local/bin/gem-mirror-update':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/openstack_project/gem-mirror-update.sh',
  }

  file { '/usr/local/bin/npm-mirror-update':
    ensure   => present,
    owner    => 'root',
    group    => 'root',
    mode     => '0755',
    content  => template('openstack_project/npm-mirror-update.sh'),
  }

  cron { 'bandersnatch':
    user        => $user,
    minute      => '*/5',
    command     => 'flock -n /var/run/bandersnatch/mirror.lock bandersnatch-mirror-update >>/var/log/bandersnatch/mirror.log 2>&1',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    require     => [
       File['/usr/local/bin/bandersnatch-mirror-update'],
       File['/etc/afsadmin.keytab'],
       File['/etc/bandersnatch.keytab'],
       Class['bandersnatch::mirror']
    ]
  }

  cron { 'rubygems-mirror':
    minute      => '*/5',
    command     => 'flock -n /var/run/rubygems/mirror.lock gem-mirror-update  >>/var/log/rubygems/mirror.log 2>&1',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    require     => [
      File['/etc/afsadmin.keytab'],
      File['/etc/gem.keytab'],
      Class['openstack_project::gem_mirror'],
    ]
  }

  cron { 'npm-mirror-update':
    user        => $user,
    minute      => '*/5',
    command     => 'flock -n /var/run/npm-mirror-update/mirror.lock npm-mirror-update >>/var/log/npm-mirror-update/mirror.log 2>&1',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    require     => [
      File['/usr/local/bin/npm-mirror-update'],
      File['/etc/afsadmin.keytab'],
      File['/etc/npm.keytab'],
      Class['openstack_project::npm_mirror'],
    ]
  }

  file { '/etc/reprepro.keytab':
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => $reprepro_keytab,
  }

  file { '/usr/local/bin/reprepro-mirror-update':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/openstack_project/reprepro/reprepro-mirror-update.sh',
  }

  ### Debian mirror ###
  ::openstack_project::reprepro { 'debian-reprepro-mirror':
    confdir       => '/etc/reprepro/debian',
    basedir       => '/afs/.openstack.org/mirror/debian',
    distributions => 'openstack_project/reprepro/distributions.debian.erb',
    updates_file  => 'puppet:///modules/openstack_project/reprepro/debuntu-updates',
    releases      => ['jessie'],
  }

  cron { 'reprepro debian':
    user        => $user,
    hour        => '*/2',
    minute      => '0',
    command     => 'flock -n /var/run/reprepro/debian.lock reprepro-mirror-update /etc/reprepro/debian mirror.debian >>/var/log/reprepro/debian-mirror.log 2>&1',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    require     => [
       File['/usr/local/bin/reprepro-mirror-update'],
       File['/etc/afsadmin.keytab'],
       File['/etc/reprepro.keytab'],
       ::Openstack_project::Reprepro['debian-reprepro-mirror'],
    ]
  }

  gnupg_key { 'Debian Archive':
    ensure     => present,
    key_id     => '7638d0442b90d010',
    user       => 'root',
    key_source => 'puppet:///modules/openstack_project/reprepro/debian-mirror-gpg-key.asc',
    key_type   => 'public',
  }

  ::openstack_project::reprepro { 'ubuntu-reprepro-mirror':
    confdir       => '/etc/reprepro/ubuntu',
    basedir       => '/afs/.openstack.org/mirror/ubuntu',
    distributions => 'openstack_project/reprepro/distributions.ubuntu.erb',
    updates_file  => 'puppet:///modules/openstack_project/reprepro/debuntu-updates',
    releases      => ['trusty', 'xenial'],
  }

  cron { 'reprepro ubuntu':
    user        => $user,
    hour        => '*/2',
    minute      => '0',
    command     => 'flock -n /var/run/reprepro/ubuntu.lock reprepro-mirror-update /etc/reprepro/ubuntu mirror.ubuntu >>/var/log/reprepro/ubuntu-mirror.log 2>&1',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    require     => [
       File['/usr/local/bin/reprepro-mirror-update'],
       File['/etc/afsadmin.keytab'],
       File['/etc/reprepro.keytab'],
       ::Openstack_project::Reprepro['ubuntu-reprepro-mirror'],
    ]
  }

  gnupg_key { 'Ubuntu Archive':
    ensure     => present,
    key_id     => '40976EAF437D05B5',
    user       => 'root',
    key_server => 'hkp://keyserver.ubuntu.com',
    key_type   => 'public',
  }

  ::openstack_project::reprepro { 'debian-ceph-hammer-reprepro-mirror':
    confdir       => '/etc/reprepro/debian-ceph-hammer',
    basedir       => '/afs/.openstack.org/mirror/ceph-deb-hammer',
    distributions => 'openstack_project/reprepro/distributions.debian-ceph-hammer.erb',
    updates_file  => 'puppet:///modules/openstack_project/reprepro/debian-ceph-hammer-updates',
    releases      => ['trusty', 'xenial'],
  }

  cron { 'reprepro debian ceph hammer':
    user        => $user,
    hour        => '*/2',
    minute      => '0',
    command     => 'flock -n /var/run/reprepro/debian-ceph-hammer.lock reprepro-mirror-update /etc/reprepro/debian-ceph-hammer mirror.deb-hammer >>/var/log/reprepro/debian-ceph-hammer-mirror.log 2>&1',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    require     => [
       File['/usr/local/bin/reprepro-mirror-update'],
       File['/etc/afsadmin.keytab'],
       File['/etc/reprepro.keytab'],
       ::Openstack_project::Reprepro['debian-ceph-hammer-reprepro-mirror'],
    ]
  }

  ::openstack_project::reprepro { 'debian-ceph-jewel-reprepro-mirror':
    confdir       => '/etc/reprepro/debian-ceph-jewel',
    basedir       => '/afs/.openstack.org/mirror/ceph-deb-jewel',
    distributions => 'openstack_project/reprepro/distributions.debian-ceph-jewel.erb',
    updates_file  => 'puppet:///modules/openstack_project/reprepro/debian-ceph-jewel-updates',
    releases      => ['trusty', 'xenial'],
  }

  cron { 'reprepro debian ceph jewel':
    user        => $user,
    hour        => '*/2',
    minute      => '0',
    command     => 'flock -n /var/run/reprepro/debian-ceph-jewel.lock reprepro-mirror-update /etc/reprepro/debian-ceph-jewel mirror.deb-jewel >>/var/log/reprepro/debian-ceph-jewel-mirror.log 2>&1',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    require     => [
       File['/usr/local/bin/reprepro-mirror-update'],
       File['/etc/afsadmin.keytab'],
       File['/etc/reprepro.keytab'],
       ::Openstack_project::Reprepro['debian-ceph-jewel-reprepro-mirror'],
    ]
  }

  gnupg_key { 'Ceph Archive':
    ensure     => present,
    # 08B7 3419 AC32 B4E9 66C1  A330 E84A C2C0 460F 3994
    key_id     => 'E84AC2C0460F3994',
    user       => 'root',
    key_type   => 'public',
    key_source => 'puppet:///modules/openstack_project/reprepro/ceph-mirror-gpg-key.asc',
  }

  ### CentOS mirror ###
  file { '/etc/centos.keytab':
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => $centos_keytab,
  }

  file { '/usr/local/bin/centos-mirror-update':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/openstack_project/mirror/centos-mirror-update.sh',
  }

  cron { 'centos mirror':
    user        => $user,
    minute      => '0',
    hour        => '*/2',
    command     => 'flock -n /var/run/centos-mirror.lock centos-mirror-update mirror.centos >>/var/log/centos-mirror.log 2>&1',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    require     => [
       File['/usr/local/bin/centos-mirror-update'],
       File['/etc/afsadmin.keytab'],
       File['/etc/centos.keytab'],
    ]
  }

  ### EPEL mirror ###
  file { '/etc/epel.keytab':
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => $epel_keytab,
  }

  file { '/usr/local/bin/epel-mirror-update':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/openstack_project/mirror/epel-mirror-update.sh',
  }

  cron { 'epel mirror':
    user        => $user,
    minute      => '0',
    hour        => '*/2',
    command     => 'flock -n /var/run/epel-mirror.lock epel-mirror-update mirror.epel >>/var/log/epel-mirror.log 2>&1',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    require     => [
       File['/usr/local/bin/epel-mirror-update'],
       File['/etc/afsadmin.keytab'],
       File['/etc/epel.keytab'],
    ]
  }

  ### Fedora mirror ###
  file { '/etc/fedora.keytab':
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => $fedora_keytab,
  }

  file { '/usr/local/bin/fedora-mirror-update':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/openstack_project/mirror/fedora-mirror-update.sh',
  }

  cron { 'fedora mirror':
    user        => $user,
    minute      => '0',
    hour        => '*/2',
    command     => 'flock -n /var/run/fedora-mirror.lock fedora-mirror-update mirror.fedora >>/var/log/fedora-mirror.log 2>&1',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    require     => [
       File['/usr/local/bin/fedora-mirror-update'],
       File['/etc/afsadmin.keytab'],
       File['/etc/fedora.keytab'],
    ]
  }

  ### openSUSE mirror ###
  file { '/etc/opensuse.keytab':
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => $opensuse_keytab,
  }

  file { '/usr/local/bin/opensuse-mirror-update':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/openstack_project/mirror/opensuse-mirror-update.sh',
  }

  cron { 'opensuse mirror':
    user        => $user,
    minute      => '0',
    hour        => '*/6',
    command     => 'flock -n /var/run/opensuse-mirror.lock opensuse-mirror-update mirror.opensuse >>/var/log/opensuse-mirror.log 2>&1',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    require     => [
       File['/usr/local/bin/opensuse-mirror-update'],
       File['/etc/afsadmin.keytab'],
       File['/etc/opensuse.keytab'],
    ]
  }

  ### Ubuntu Cloud Archive Mirror ###
  ::openstack_project::reprepro { 'ubuntu-cloud-archive-reprepro-mirror':
    confdir       => '/etc/reprepro/ubuntu-cloud-archive',
    basedir       => '/afs/.openstack.org/mirror/ubuntu-cloud-archive',
    distributions => 'openstack_project/reprepro/distributions.ubuntu-cloud-archive.erb',
    updates_file  => 'puppet:///modules/openstack_project/reprepro/ubuntu-cloud-archive-updates',
    releases      => { 'trusty'=>['liberty', 'mitaka'], 'xenial'=>['newton', 'ocata', 'pike'] },
  }

  cron { 'reprepro ubuntu-cloud-archive':
    user        => $user,
    hour        => '*/2',
    minute      => '0',
    command     => 'flock -n /var/run/reprepro/ubuntu-cloud-archive.lock reprepro-mirror-update /etc/reprepro/ubuntu-cloud-archive mirror.ubuntu-cloud >>/var/log/reprepro/ubuntu-cloud-archive-mirror.log 2>&1',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    require     => [
       File['/usr/local/bin/reprepro-mirror-update'],
       File['/etc/afsadmin.keytab'],
       File['/etc/reprepro.keytab'],
       ::Openstack_project::Reprepro['ubuntu-cloud-archive-reprepro-mirror'],
    ]
  }

  gnupg_key { 'Canonical Cloud Archive Signing Key':
    ensure     => present,
    # 391A 9AA2 1471 9283 9E9D  B031 5EDB 1B62 EC49 26EA
    key_id     => '5EDB1B62EC4926EA',
    user       => 'root',
    key_type   => 'public',
    key_source => 'puppet:///modules/openstack_project/reprepro/ubuntu-cloud-archive-gpg-key.asc',
  }

  ### MariaDB mirror ###
  ::openstack_project::mariadb_mirror { '10.0':
    require => [
       File['/usr/local/bin/reprepro-mirror-update'],
       File['/etc/afsadmin.keytab'],
       File['/etc/reprepro.keytab'],
    ]
  }
  ::openstack_project::mariadb_mirror { '10.1':
    require => [
       File['/usr/local/bin/reprepro-mirror-update'],
       File['/etc/afsadmin.keytab'],
       File['/etc/reprepro.keytab'],
    ]
  }

  gnupg_key { 'MariaDB Package Signing Key':
    ensure     => present,
    # 1993 69E5 404B D5FC 7D2F E43B CBCB 082A 1BB9 43DB
    key_id     => 'CBCB082A1BB943DB',
    user       => 'root',
    key_type   => 'public',
    key_source => 'puppet:///modules/openstack_project/reprepro/mariadb-mirror-gpg-key.asc',
  }
}
