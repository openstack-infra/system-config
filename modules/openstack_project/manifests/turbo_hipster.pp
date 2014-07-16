# == Class: openstack_project::turbo_hipster
#
class openstack_project::turbo_hipster (
  $sysadmins = [],
  $th_repo = 'https://git.openstack.org/stackforge/turbo-hipster',
  $th_repo_destination = '/home/th/turbo-hipster',
  $th_user = 'th',
  $th_test_user = 'nova',
  $th_test_pass = 'tester',
  $gerrit_site = 'http://review.openstack.org',
  $gearman_server = 'zuul.openstack.org',
  $gearman_port = 4730,
  $pypi_mirror = 'http://pypi.python.org',
  $ssh_private_key = '',
  $rs_cloud_user = '',
  $rs_cloud_pass = '',
  $manage_start_script = true,
  $plugin = 'noop_ci',
  $stop_puppet = true,
  $shutdown_check = true,
  $shutdown_th = true,
  $debug_str   = '',
) {
  include openstack_project

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [4730],
    sysadmins                 => $sysadmins,
  }
  include bup
  bup::site { 'rs-ord':
    backup_user   => 'bup-jenkins-dev',
    backup_server => 'ci-backup-rs-ord.openstack.org',
  }

  class { '::turbo_hipster':
    th_repo                  => $th_repo,
    th_repo_destination      => $th_repo_destination,
    th_user                  => $th_user,
    gearman_server           => $gearman_server,
    gearman_port             => $gearman_port,
    pypi_mirror              => $pypi_mirror,
    ssh_private_key          => $ssh_private_key,
    rs_cloud_user            => $rs_cloud_user,
    rs_cloud_pass            => $rs_cloud_pass,
    manage_start_script      => $manage_start_script,
    shutdown_check           => $shutdown_check,
  }

  if ($plugin == 'noop_ci') {
    class { '::turbo_hipster::noop_ci': }
  }
}
