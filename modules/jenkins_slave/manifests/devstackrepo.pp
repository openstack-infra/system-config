define devstackrepo($ensure = present) {
  $repo_there = "test -d /home/jenkins/devstack"
  $mysql_pass = $orchestra::mysql_pass
  $rabbit_pass = generate('/usr/bin/openssl', 'rand', '-hex', '12')
  case $ensure {
    present: {
      exec { "Clone devstack git repo":
        path        => "/usr/sbin:/usr/bin:/sbin:/bin",
        environment => "HOME=/home/jenkins",
        command     => "sudo -H -u jenkins -i git clone git://github.com/jeblair/devstack.git /home/jenkins/devstack",
        user        => "root",
        group       => "root",
        unless      => "$repo_there",
        logoutput   => on_failure,
      }
      file { '/home/jenkins/devstack/localrc':
        owner => 'root',
        group => 'root',
        mode => 444,
        ensure => 'present',
        content => template('jenkins_slave/localrc.erb'),
        replace => 'false',
	require => [Exec["Clone devstack git repo"],
	            File["/var/lib/cobbler/snippets/openstack_mysql_password"],
		    ]
      }
      exec { "Update devstack git repo":
        path        => "/usr/sbin:/usr/bin:/sbin:/bin",
        environment => "HOME=/home/jenkins",
        command     => "sudo -H -u jenkins -i bash -c 'cd /home/jenkins/devstack && git pull'",
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
        command => "rm -rf /home/jenkins/devstack",
        user    => "root",
        group   => "root",
        onlyif  => "$repo_there",
      }
    }
    default: {
      fail "Invalid 'ensure' value '$ensure' for devstackrepo"
    }
  }
}
