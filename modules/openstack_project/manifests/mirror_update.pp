# == Class: openstack_project::mirror_update
#
class openstack_project::mirror_update (
  $reprepro_keytab = '',
  $admin_keytab = '',
  $gem_keytab = '',
  $centos_keytab = '',
  $epel_keytab = '',
  $yum_puppetlabs_keytab = '',
  $fedora_keytab = '',
  $opensuse_keytab = '',
) {
  include ::gnupg
  include ::openstack_project::reprepro_mirror

  class { 'openstack_project::server':
    afs       => true,
  }

  class { 'openstack_project::gem_mirror': }

  file { '/etc/gem.keytab':
    owner   => 'rubygems',
    group   => 'root',
    mode    => '0400',
    content => $gem_keytab,
    require  => Class['openstack_project::gem_mirror'],
  }

  file { '/etc/afsadmin.keytab':
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => $admin_keytab,
  }

  file { '/usr/local/bin/gem-mirror-update':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/openstack_project/gem-mirror-update.sh',
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
    releases      => ['stretch', 'buster'],
  }

  cron { 'reprepro debian':
    user        => 'root',
    hour        => '*/2',
    minute      => fqdn_rand(45, 'reprepro-debian'),
    command     => 'flock -n /var/run/reprepro/debian.lock reprepro-mirror-update /etc/reprepro/debian mirror.debian >>/var/log/reprepro/debian-mirror.log 2>&1',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    require     => [
       File['/usr/local/bin/reprepro-mirror-update'],
       File['/etc/afsadmin.keytab'],
       File['/etc/reprepro.keytab'],
       ::Openstack_project::Reprepro['debian-reprepro-mirror'],
    ]
  }

  gnupg_key { 'Debian 9/stretch Archive':
    ensure     => present,
    key_id     => 'E0B11894F66AEC98',
    user       => 'root',
    key_source => 'puppet:///modules/openstack_project/reprepro/debian-stretch-mirror-gpg-key.asc',
    key_type   => 'public',
  }

  # Note debian-security needs it's own mirroring process, as we found
  # that including it in the main "debuntu-updates" config lead to
  # weird conflicts of package names breaking the mirror.
  ::openstack_project::reprepro { 'debian-security-reprepro-mirror':
    confdir       => '/etc/reprepro/debian-security',
    basedir       => '/afs/.openstack.org/mirror/debian-security',
    distributions => 'openstack_project/reprepro/distributions.debian-security.erb',
    updates_file  => 'puppet:///modules/openstack_project/reprepro/debian-security-updates',
    releases      => ['stretch', 'buster'],
  }

  cron { 'reprepro debian security':
    user        => 'root',
    hour        => '*/2',
    minute      => fqdn_rand(45, 'reprepro-debian-security'),
    command     => 'flock -n /var/run/reprepro/debian-security.lock reprepro-mirror-update /etc/reprepro/debian-security mirror.debian-security >>/var/log/reprepro/debian-security-mirror.log 2>&1',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    require     => [
       File['/usr/local/bin/reprepro-mirror-update'],
       File['/etc/afsadmin.keytab'],
       File['/etc/reprepro.keytab'],
       ::Openstack_project::Reprepro['debian-security-reprepro-mirror'],
    ]
  }

  gnupg_key { 'Debian 9/stretch Security':
    ensure     => present,
    key_id     => 'EDA0D2388AE22BA9',
    user       => 'root',
    key_source => 'puppet:///modules/openstack_project/reprepro/debian-stretch-security-mirror-gpg-key.asc',
    key_type   => 'public',
  }

  ::openstack_project::reprepro { 'ubuntu-reprepro-mirror':
    confdir       => '/etc/reprepro/ubuntu',
    basedir       => '/afs/.openstack.org/mirror/ubuntu',
    distributions => 'openstack_project/reprepro/distributions.ubuntu.erb',
    updates_file  => 'puppet:///modules/openstack_project/reprepro/debuntu-updates',
    releases      => ['bionic', 'trusty', 'xenial'],
  }

  cron { 'reprepro ubuntu':
    user        => 'root',
    hour        => '*/2',
    minute      => fqdn_rand(45, 'reprepro-ubuntu'),
    command     => 'flock -n /var/run/reprepro/ubuntu.lock reprepro-mirror-update /etc/reprepro/ubuntu mirror.ubuntu >>/var/log/reprepro/ubuntu-mirror.log 2>&1',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    require     => [
       File['/usr/local/bin/reprepro-mirror-update'],
       File['/etc/afsadmin.keytab'],
       File['/etc/reprepro.keytab'],
       ::Openstack_project::Reprepro['ubuntu-reprepro-mirror'],
    ]
  }

  ::openstack_project::reprepro { 'ubuntu-ports-reprepro-mirror':
    confdir       => '/etc/reprepro/ubuntu-ports',
    basedir       => '/afs/.openstack.org/mirror/ubuntu-ports',
    distributions => 'openstack_project/reprepro/distributions.ubuntu-ports.erb',
    updates_file  => 'puppet:///modules/openstack_project/reprepro/debuntu-updates',
    releases      => ['bionic', 'xenial'],
  }

  cron { 'reprepro ubuntu-ports':
    user        => 'root',
    hour        => '*/2',
    minute      => fqdn_rand(45, 'reprepro-ubuntu-ports'),
    command     => 'flock -n /var/run/reprepro/ubuntu-ports.lock reprepro-mirror-update /etc/reprepro/ubuntu-ports mirror.ubuntu-ports >>/var/log/reprepro/ubuntu-ports-mirror.log 2>&1',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    require     => [
       File['/usr/local/bin/reprepro-mirror-update'],
       File['/etc/afsadmin.keytab'],
       File['/etc/reprepro.keytab'],
       ::Openstack_project::Reprepro['ubuntu-ports-reprepro-mirror'],
    ]
  }

  gnupg_key { 'Ubuntu Archive':
    ensure     => present,
    key_id     => '40976EAF437D05B5',
    user       => 'root',
    key_server => 'hkp://keyserver.ubuntu.com',
    key_type   => 'public',
  }

  gnupg_key { 'Ubuntu Archive (2012)':
    ensure     => present,
    key_id     => '3B4FE6ACC0B21F32',
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
    user        => 'root',
    hour        => '*/2',
    minute      => fqdn_rand(45, 'debian-ceph-hammer'),
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
    user        => 'root',
    hour        => '*/2',
    minute      => fqdn_rand(45, 'debian-ceph-jewel'),
    command     => 'flock -n /var/run/reprepro/debian-ceph-jewel.lock reprepro-mirror-update /etc/reprepro/debian-ceph-jewel mirror.deb-jewel >>/var/log/reprepro/debian-ceph-jewel-mirror.log 2>&1',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    require     => [
       File['/usr/local/bin/reprepro-mirror-update'],
       File['/etc/afsadmin.keytab'],
       File['/etc/reprepro.keytab'],
       ::Openstack_project::Reprepro['debian-ceph-jewel-reprepro-mirror'],
    ]
  }

  ::openstack_project::reprepro { 'debian-ceph-luminous-reprepro-mirror':
    confdir       => '/etc/reprepro/debian-ceph-luminous',
    basedir       => '/afs/.openstack.org/mirror/ceph-deb-luminous',
    distributions => 'openstack_project/reprepro/distributions.debian-ceph-luminous.erb',
    updates_file  => 'puppet:///modules/openstack_project/reprepro/debian-ceph-luminous-updates',
    releases      => ['stretch', 'xenial'],
  }

  cron { 'reprepro debian ceph luminous':
    user        => 'root',
    hour        => '*/2',
    minute      => fqdn_rand(45, 'debian-ceph-luminous'),
    command     => 'flock -n /var/run/reprepro/debian-ceph-luminous.lock reprepro-mirror-update /etc/reprepro/debian-ceph-luminous mirror.deb-luminous >>/var/log/reprepro/debian-ceph-luminous-mirror.log 2>&1',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    require     => [
       File['/usr/local/bin/reprepro-mirror-update'],
       File['/etc/afsadmin.keytab'],
       File['/etc/reprepro.keytab'],
       ::Openstack_project::Reprepro['debian-ceph-luminous-reprepro-mirror'],
    ]
  }

  ::openstack_project::reprepro { 'debian-ceph-mimic-reprepro-mirror':
    confdir       => '/etc/reprepro/debian-ceph-mimic',
    basedir       => '/afs/.openstack.org/mirror/ceph-deb-mimic',
    distributions => 'openstack_project/reprepro/distributions.debian-ceph-mimic.erb',
    updates_file  => 'puppet:///modules/openstack_project/reprepro/debian-ceph-mimic-updates',
    releases      => ['stretch', 'xenial', 'bionic'],
  }

  cron { 'reprepro debian ceph mimic':
    user        => 'root',
    hour        => '*/2',
    minute      => fqdn_rand(45, 'debian-ceph-mimic'),
    command     => 'flock -n /var/run/reprepro/debian-ceph-mimic.lock reprepro-mirror-update /etc/reprepro/debian-ceph-mimic mirror.deb-mimic >>/var/log/reprepro/debian-ceph-mimic-mirror.log 2>&1',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    require     => [
       File['/usr/local/bin/reprepro-mirror-update'],
       File['/etc/afsadmin.keytab'],
       File['/etc/reprepro.keytab'],
       ::Openstack_project::Reprepro['debian-ceph-mimic-reprepro-mirror'],
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

  ## Docker APT mirror
  ::openstack_project::reprepro { 'debian-docker-reprepro-mirror':
    confdir       => '/etc/reprepro/debian-docker',
    basedir       => '/afs/.openstack.org/mirror/deb-docker',
    distributions => 'openstack_project/reprepro/distributions.debian-docker.erb',
    updates_file  => 'puppet:///modules/openstack_project/reprepro/debian-docker-updates',
    releases      => ['xenial'],
  }

  cron { 'reprepro debian docker':
    user        => 'root',
    hour        => '*/2',
    minute      => fqdn_rand(45, 'debian-docker'),
    command     => 'flock -n /var/run/reprepro/debian-docker.lock reprepro-mirror-update /etc/reprepro/debian-docker mirror.deb-docker >>/var/log/reprepro/debian-docker-mirror.log 2>&1',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    require     => [
       File['/usr/local/bin/reprepro-mirror-update'],
       File['/etc/afsadmin.keytab'],
       File['/etc/reprepro.keytab'],
       ::Openstack_project::Reprepro['debian-docker-reprepro-mirror'],
    ]
  }

  gnupg_key { 'Docker Archive':
    ensure     => present,
    # pub  4096R/0EBFCD88 2017-02-22 Docker Release (CE deb) <docker@docker.com>
    # fingerprint: 9DC8 5822 9FC7 DD38 854A E2D8 8D81 803C 0EBF CD88
    # Note the key that signs the release file is actually the subkey F273FCD8
    key_id     => '0EBFCD88',
    user       => 'root',
    key_type   => 'public',
    key_source => 'puppet:///modules/openstack_project/reprepro/docker-mirror-gpg-key.asc',
  }

  ## Puppetlabs APT mirror
  ::openstack_project::reprepro { 'apt-puppetlabs-reprepro-mirror':
    confdir       => '/etc/reprepro/apt-puppetlabs',
    basedir       => '/afs/.openstack.org/mirror/apt-puppetlabs',
    distributions => 'openstack_project/reprepro/distributions.apt-puppetlabs.erb',
    updates_file  => 'puppet:///modules/openstack_project/reprepro/puppetlabs-debs',
    releases      => { 'xenial' => 'PC1 puppet5', 'stretch' => 'PC1 puppet5 puppet6', 'bionic' => 'puppet5 puppet6' },
  }

  cron { 'reprepro ubuntu puppetlabs':
    user        => 'root',
    hour        => '*/2',
    minute      => fqdn_rand(45, 'ubuntu-puppetlabs'),
    command     => 'flock -n /var/run/reprepro/apt-puppetlabs.lock reprepro-mirror-update /etc/reprepro/apt-puppetlabs mirror.apt-puppetlabs >>/var/log/reprepro/apt-puppetlabs-mirror.log 2>&1',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    require     => [
       File['/usr/local/bin/reprepro-mirror-update'],
       File['/etc/afsadmin.keytab'],
       File['/etc/reprepro.keytab'],
       ::Openstack_project::Reprepro['apt-puppetlabs-reprepro-mirror'],
    ]
  }

  gnupg_key { 'Puppetlabs Archive':
    ensure     => present,
    key_id     => 'EF8D349F',
    user       => 'root',
    key_type   => 'public',
    key_source => 'puppet:///modules/openstack_project/reprepro/puppetlabs-mirror-gpg-key.asc',
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
    user        => 'root',
    minute      => fqdn_rand(45, 'centos-mirror'),
    hour        => '*/2',
    command     => 'flock -n /var/run/centos-mirror.lock centos-mirror-update mirror.centos >>/var/log/centos-mirror.log 2>&1',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    require     => [
       File['/usr/local/bin/centos-mirror-update'],
       File['/etc/afsadmin.keytab'],
       File['/etc/centos.keytab'],
    ]
  }

  ### RDO mirror ###
  file { '/etc/rdo.keytab':
    ensure => absent,
  }

  file { '/usr/local/bin/rdo-mirror-update':
    ensure => absent,
  }

  cron { 'rdo mirror':
    ensure => absent,
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
    user        => 'root',
    minute      => fqdn_rand(45, 'epel-mirror'),
    hour        => '*/2',
    command     => 'flock -n /var/run/epel-mirror.lock epel-mirror-update mirror.epel >>/var/log/epel-mirror.log 2>&1',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    require     => [
       File['/usr/local/bin/epel-mirror-update'],
       File['/etc/afsadmin.keytab'],
       File['/etc/epel.keytab'],
    ]
  }

  ### Puppetlabs / CentOS mirror ###
  file { '/etc/yum-puppetlabs.keytab':
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => $yum_puppetlabs_keytab,
  }

  file { '/usr/local/bin/yum-puppetlabs-mirror-update':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/openstack_project/mirror/yum-puppetlabs-mirror-update.sh',
  }

  cron { 'yum-puppetlabs mirror':
    user        => 'root',
    minute      => fqdn_rand(45, 'yum-puppetlabs'),
    hour        => '*/2',
    command     => 'flock -n /var/run/yum-puppetlabs-mirror.lock yum-puppetlabs-mirror-update mirror.yum-puppetlabs >>/var/log/yum-puppetlabs-mirror.log 2>&1',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    require     => [
       File['/usr/local/bin/yum-puppetlabs-mirror-update'],
       File['/etc/afsadmin.keytab'],
       File['/etc/yum-puppetlabs.keytab'],
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
    user        => 'root',
    minute      => fqdn_rand(45, 'fedora-mirror'),
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
    user        => 'root',
    minute      => fqdn_rand(45, 'opensuse-mirror'),
    hour        => '*/2',
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
    releases      => { 'trusty'=>['liberty', 'mitaka'], 'xenial'=>['newton', 'ocata', 'pike', 'queens'], 'bionic'=>['rocky', 'stein'] },
  }

  cron { 'reprepro ubuntu-cloud-archive':
    user        => 'root',
    hour        => '*/2',
    minute      => fqdn_rand(45, 'ubuntu-cloud-archive-mirror'),
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

  # AFS Monitoring
  file { '/etc/afsmon.cfg':
    ensure => present,
    content => template('openstack_project/mirror-update/afsmon.cfg.erb'),
    replace => true,
  }

  vcsrepo { '/opt/afsmon':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://git.openstack.org/openstack-infra/afsmon',
  }

  python::virtualenv { '/usr/afsmon-env':
    ensure     => present,
    owner      => 'root',
    group      => 'root',
    timeout    => 0,
    # puppet-python 1.9.4 wants to guess we want "virtualenv-3", which
    # we don't.  Fixed in later versions.
    virtualenv => 'virtualenv',
    version    => 3,
  }

  exec { 'install_afsmon' :
    command     => '/usr/afsmon-env/bin/pip install --upgrade /opt/afsmon',
    path        => '/usr/local/bin:/usr/bin:/bin',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/afsmon'],
    require     => Python::Virtualenv['/usr/afsmon-env'],
  }

  cron { 'afsmon':
    minute      => [0, 30],
    command     => '/usr/afsmon-env/bin/afsmon statsd >> /var/log/afsmon.log 2>&1',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    require     => [
                    Python::Virtualenv['/usr/afsmon-env'],
                    Exec['install_afsmon'],
                    File['/etc/afsmon.cfg'],
                   ],
  }

}
