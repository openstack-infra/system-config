# == Class: openstack_project::zuul_merger
#
class openstack_project::zuul_merger(
  $vhost_name = $::fqdn,
  $gearman_server = '127.0.0.1',
  $gerrit_server = '',
  $gerrit_user = '',
  $gerrit_ssh_host_key = '',
  $zuul_ssh_private_key = '',
  $zuul_url = "http://${::fqdn}/p",
  $git_email = 'jenkins@openstack.org',
  $git_name = 'OpenStack Jenkins',
  $revision = 'master',
  $manage_common_zuul = true,
) {
  class { 'openstackci::zuul_merger':
    vhost_name               => $vhost_name,
    gearman_server           => $gearman_server,
    gerrit_server            => $gerrit_server,
    gerrit_user              => $gerrit_user,
    known_hosts_content      => "review.openstack.org,23.253.232.87,2001:4800:7815:104:3bc3:d7f6:ff03:bf5d ${gerrit_ssh_host_key}\ngit.opendaylight.org,52.35.122.251,2600:1f14:421:f500:7b21:2a58:ab0a:2d17 ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBJbPbJvIQZ4BzdfV13OUj+R4pGwX7tLv7DG8LzzEw3XSAUmHx50E4ObKrpTMEAUZ3Gt6QrrnVr1VXrs+134m7IY=",
    zuul_ssh_private_key     => $zuul_ssh_private_key,
    zuul_url                 => $zuul_url,
    git_email                => $git_email,
    git_name                 => $git_name,
    manage_common_zuul       => $manage_common_zuul,
    revision                 => $revision,
  }
}
