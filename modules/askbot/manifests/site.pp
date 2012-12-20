define askbot::site (
  $mysql_password
) {
  include askbot

  # Configure askbot site
  file { "/opt/askbot/askbotsite${name}":
    ensure  => directory,
    owner   => 'askbot',
    group   => 'www-data',
    mode    => '0640',
    require => File['/opt/askbot'],
  }

  file { "/opt/askbot/askbotsite${name}/django.wsgi":
    owner   => 'askbot',
    group   => 'www-data',
    mode    => '0640',
    source  => 'puppet:///modules/askbot/django.wsgi',
    require => File["/opt/askbot/askbotsite${name}"],
  }

  file { "/opt/askbot/askbotsite${name}/__init__.py":
    owner   => 'askbot',
    group   => 'www-data',
    mode    => '0640',
    content => '',
    require => File["/opt/askbot/askbotsite${name}"],
  }

  file { "/opt/askbot/askbotsite${name}/manage.py":
    owner   => 'askbot',
    group   => 'www-data',
    mode    => '0640',
    source  => 'puppet:///modules/askbot/manage.py',
    require => File["/opt/askbot/askbotsite${name}"],
  }

  file { "/opt/askbot/askbotsite${name}/settings.py":
    owner   => 'askbot',
    group   => 'www-data',
    mode    => '0640',
    content => template('askbot/askbot_settings.erb'),
    require => File["/opt/askbot/askbotsite${name}"],
  }

  file { "/opt/askbot/askbotsite${name}/urls.py":
    owner   => 'askbot',
    group   => 'www-data',
    mode    => '0640',
    source  => 'puppet:///modules/askbot/urls.py',
    require => File["/opt/askbot/askbotsite${name}"],
  }

  file { "/opt/askbot/askbotsite${name}/log":
    ensure  => directory,
    owner   => 'askbot',
    group   => 'www-data',
    mode    => '0660',
    require => File["/opt/askbot/askbotsite${name}"],
  }

  file { "/opt/askbot/askbotsite${name}/log/askbot.log":
    owner   => 'askbot',
    group   => 'www-data',
    mode    => '0660',
    require => File["/opt/askbot/askbotsite${name}/log"],
  }

  file { "/opt/askbot/askbotsite${name}/askbot":
    ensure  => directory,
    owner   => 'askbot',
    group   => 'www-data',
    mode    => '0660',
    require => File["/opt/askbot/askbotsite${name}"],
  }

  file { "/opt/askbot/askbotsite${name}/askbot/upfiles":
    ensure  => directory,
    owner   => 'askbot',
    group   => 'www-data',
    mode    => '0660',
    require => File["/opt/askbot/askbotsite${name}/askbot"],
  }
}
