define askbot::deploy (
  $vhost_name = $::fqdn
) {
  exec { 'syncdb':
    command     => 'python manage.py syncdb',
    cwd         => "/opt/askbot/askbotsite${name}",
    path        => '/bin:/usr/bin',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/askbot/askbot-devel'],
    require     => [
        Askbot::Site[$name],
        Askbot::Mysql[$name],
    ],
  }

  exec { 'migrate_askbot':
    command     => 'python manage.py migrate askbot',
    cwd         => "/opt/askbot/askbotsite${name}",
    path        => '/bin:/usr/bin',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/askbot/askbot-devel'],
    require     => [
        Askbot::Site[$name],
        Askbot::Mysql[$name],
    ],
  }

  exec { 'migrate_djangoauth':
    command     => 'python manage.py migrate django_authopenid',
    cwd         => "/opt/askbot/askbotsite${name}",
    path        => '/bin:/usr/bin',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/askbot/askbot-devel'],
    require     => [
        Askbot::Site[$name],
        Askbot::Mysql[$name],
    ],
  }

  exec { 'collectstatic':
    command     => 'python manage.py collectstatic',
    cwd         => "/opt/askbot/askbotsite${name}",
    path        => '/bin:/usr/bin',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/askbot/askbot-devel'],
    require     => [
        Askbot::Site[$name],
        Askbot::Mysql[$name],
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
