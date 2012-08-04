define meetbot::site($nick, $nickpass, $network, $server, $vhost_name=$fqdn, $channels, $use_ssl) {

  include remove_nginx

  apache::vhost { $vhost_name:
    port => 80,
    docroot => "/srv/meetbot-$name",
    priority => '50',
  }

  file { "/var/lib/meetbot/${name}":
    ensure => directory,
    owner => 'meetbot',
    require => File["/var/lib/meetbot"]
  }

  file { "/srv/meetbot-${name}":
    ensure => directory,
  }

  file { "/srv/meetbot-${name}/index.html":
    ensure => present,
    content => template("meetbot/index.html.erb"),
    require => File["/srv/meetbot-${name}"]
  }

  file { "/srv/meetbot-${name}/irclogs":
    ensure => link,
    target => "/var/lib/meetbot/${name}/logs/ChannelLogger/${network}/",
    require => File["/srv/meetbot-${name}"]
  }

  file { "/srv/meetbot-${name}/meetings":
    ensure => link,
    target => "/var/lib/meetbot/${name}/meetings/",
    require => File["/srv/meetbot-${name}"]
  }


  file { "/var/lib/meetbot/${name}/conf":
    ensure => directory,
    owner => 'meetbot',
    require => File["/var/lib/meetbot/${name}"]
  }

  file { "/var/lib/meetbot/${name}/data":
    ensure => directory,
    owner => 'meetbot',
    require => File["/var/lib/meetbot/${name}"]
  }

  file { "/var/lib/meetbot/${name}/data/tmp":
    ensure => directory,
    owner => 'meetbot',
    require => File["/var/lib/meetbot/${name}/data"]
  }

  file { "/var/lib/meetbot/${name}/backup":
    ensure => directory,
    owner => 'meetbot',
    require => File["/var/lib/meetbot/${name}"]
  }

  file { "/var/lib/meetbot/${name}/logs":
    ensure => directory,
    owner => 'meetbot',
    require => File["/var/lib/meetbot/${name}"]
  }

  # set to root/root so meetbot doesn't overwrite
  file { "/var/lib/meetbot/${name}.conf":
    ensure => present,
    content => template("meetbot/supybot.conf.erb"),
    owner => 'root',
    group => 'root',
    require => File["/var/lib/meetbot"],
    notify => Service["${name}-meetbot"]
  }

  file { "/var/lib/meetbot/${name}/ircmeeting":
    ensure => directory,
    recurse => true,
    source => "/opt/meetbot/ircmeeting",
    owner => 'meetbot',
    require => [Vcsrepo["/opt/meetbot"],
                File["/var/lib/meetbot/${name}"]]
  }

  file { "/var/lib/meetbot/${name}/ircmeeting/meetingLocalConfig.py":
    ensure => present,
    content => template("meetbot/meetingLocalConfig.py.erb"),
    owner => 'meetbot',
    require => File["/var/lib/meetbot/${name}/ircmeeting"],
    notify => Service["${name}-meetbot"]
  }

# we set this file as root ownership because meetbot overwrites it on shutdown
# this means when puppet changes it and restarts meetbot the file is reset

  file { "/etc/init/${name}-meetbot.conf":
    ensure => 'present',
    content => template("meetbot/upstart.erb"),
    replace => 'true',
    require => File["/var/lib/meetbot/${name}.conf"],
    owner => 'root',
    notify => Service["${name}-meetbot"]
  }

  service { "${name}-meetbot":
    provider => upstart,
    ensure => running,
    require => [Vcsrepo["/opt/meetbot"],
                File["/etc/init/${name}-meetbot.conf"]],
    subscribe => [File["/usr/share/pyshared/supybot/plugins/MeetBot"],
                  File["/var/lib/meetbot/${name}/ircmeeting"]]
  }
}
