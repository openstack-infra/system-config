define slavecirepo($ensure = present) {
  $repo_there = "test -d /home/jenkins/openstack-ci"
  case $ensure {
    present: {
      exec { "Clone openstack-ci git repo":
        path        => "/usr/sbin:/usr/bin:/sbin:/bin",
        environment => "HOME=/home/jenkins",
        command     => "sudo -H -u jenkins -i git clone git://github.com/openstack/openstack-ci.git /home/jenkins/openstack-ci",
        user        => "root",
        group       => "root",
        unless      => "$repo_there",
        logoutput   => on_failure,
      }
      exec { "Update openstack-ci git repo":
        path        => "/usr/sbin:/usr/bin:/sbin:/bin",
        environment => "HOME=/home/jenkins",
        command     => "sudo -H -u jenkins -i bash -c 'cd /home/jenkins/openstack-ci && git pull'",
        user        => "root",
        group       => "root",
        onlyif      => "$repo_there",
        logoutput   => on_failure,
      }
    }
    absent:  {
      exec { "Remove OpenStack git repo":
        path    => "/usr/sbin:/usr/bin:/sbin:/bin",
        environment => "HOME=/root",
        command => "rm -rf /home/jenkins/openstack-ci",
        user    => "root",
        group   => "root",
        onlyif  => "$repo_there",
      }
    }
    default: {
      fail "Invalid 'ensure' value '$ensure' for slavecirepo"
    }
  }
}
