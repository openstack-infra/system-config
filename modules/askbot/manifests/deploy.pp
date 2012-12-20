define askbot::deploy (
  $vhost_name = $::fqdn
) {
  include askbot

  exec { "collectstatic${name}":
    command     => 'python manage.py collectstatic --noinput',
    cwd         => "/opt/askbot/askbotsite${name}",
    path        => '/bin:/usr/bin',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/askbot/askbot-devel'],
    require     => [
        Askbot::Site[$name],
        Askbot::Mysqldb[$name],
    ],
  }

  exec { "syncdb${name}":
    command     => 'python manage.py syncdb --noinput',
    cwd         => "/opt/askbot/askbotsite${name}",
    path        => '/bin:/usr/bin',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/askbot/askbot-devel'],
    require     => [
        Askbot::Site[$name],
        Askbot::Mysqldb[$name],
        Exec["collectstatic${name}"],
    ],
  }

  exec { "migrate_askbot${name}":
    command     => 'python manage.py migrate askbot',
    cwd         => "/opt/askbot/askbotsite${name}",
    path        => '/bin:/usr/bin',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/askbot/askbot-devel'],
    require     => [
        Askbot::Site[$name],
        Askbot::Mysqldb[$name],
        Exec["syncdb${name}"],
    ],
  }

  exec { "migrate_djangoauth${name}":
    command     => 'python manage.py migrate django_authopenid',
    cwd         => "/opt/askbot/askbotsite${name}",
    path        => '/bin:/usr/bin',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/askbot/askbot-devel'],
    require     => [
        Askbot::Site[$name],
        Askbot::Mysqldb[$name],
        Exec["migrate_djangoauth${name}"],
    ],
  }

  apache::vhost { $vhost_name:
    port     => 443,
    docroot  => 'MEANINGLESS ARGUMENT',
    priority => '50',
    template => "askbot/askbot${name}.vhost.erb",
    ssl      => true,
  }
}
