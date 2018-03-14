# == Define: openstack_project::mariadb_mirror
#
define openstack_project::mariadb_mirror (
) {
  ### MariaDB mirror ###
  ::openstack_project::reprepro { "ubuntu-mariadb-$name-reprepro-mirror":
    confdir       => "/etc/reprepro/ubuntu-mariadb-$name",
    basedir       => "/afs/.openstack.org/mirror/ubuntu-mariadb/$name",
    distributions => 'openstack_project/reprepro/distributions.ubuntu-mariadb.erb',
    updates_file  => "puppet:///modules/openstack_project/reprepro/ubuntu-mariadb-$name-updates",
    releases      => [ 'trusty', 'xenial' ],
  }

  # NOTE(ianw) we have several versions, but they all share the same
  # mirror.ubuntu-mariadb volume.  Start them at offset times, but
  # also share the lock so that one doesn't release the volume when
  # the other is half-complete.
  cron { "reprepro ubuntu mariadb $name":
    user        => $user,
    hour        => '*/2',
    minute      => fqdn_rand(30, $name),
    command     => "flock -w 3600 /var/run/reprepro/ubuntu-mariadb.lock reprepro-mirror-update /etc/reprepro/ubuntu-mariadb-$name mirror.ubuntu-mariadb >>/var/log/reprepro/ubuntu-mariadb-$name-mirror.log 2>&1",
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
  }
}
