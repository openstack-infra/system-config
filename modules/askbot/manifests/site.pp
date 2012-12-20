define askbot::site (
  $mysql_password,
  $ssl_cert_file_contents = '',
  $ssl_key_file_contents = '',
  $ssl_chain_file_contents = '',
  $ssl_cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem',
  $ssl_key_file = '/etc/ssl/private/ssl-cert-snakeoil.key',
  $ssl_chain_file = ''
) {
  include askbot

  # Configure askbot site
  file { "/opt/askbot/askbotsite${name}":
    ensure  => directory,
    owner   => 'askbot',
    group   => 'www-data',
    mode    => '0644',
    require => File['/opt/askbot'],
  }

  file { "/opt/askbot/askbotsite${name}/django.wsgi":
    owner   => 'askbot',
    group   => 'www-data',
    mode    => '0644',
    source  => 'puppet:///modules/askbot/django.wsgi',
    require => File["/opt/askbot/askbotsite${name}"],
  }

  file { "/opt/askbot/askbotsite${name}/__init__.py":
    owner   => 'askbot',
    group   => 'www-data',
    mode    => '0644',
    content => '',
    require => File["/opt/askbot/askbotsite${name}"],
  }

  file { "/opt/askbot/askbotsite${name}/manage.py":
    owner   => 'askbot',
    group   => 'www-data',
    mode    => '0644',
    source  => 'puppet:///modules/askbot/manage.py',
    require => File["/opt/askbot/askbotsite${name}"],
  }

  file { "/opt/askbot/askbotsite${name}/settings.py":
    owner   => 'askbot',
    group   => 'www-data',
    mode    => '0644',
    content => template('askbot/askbot_settings.erb'),
    require => File["/opt/askbot/askbotsite${name}"],
  }

  file { "/opt/askbot/askbotsite${name}/urls.py":
    owner   => 'askbot',
    group   => 'www-data',
    mode    => '0644',
    source  => 'puppet:///modules/askbot/urls.py',
    require => File["/opt/askbot/askbotsite${name}"],
  }

  file { "/opt/askbot/askbotsite${name}/log":
    ensure  => directory,
    owner   => 'askbot',
    group   => 'www-data',
    mode    => '0664',
    require => File["/opt/askbot/askbotsite${name}"],
  }

  file { "/opt/askbot/askbotsite${name}/log/askbot.log":
    owner   => 'askbot',
    group   => 'www-data',
    mode    => '0664',
    require => File["/opt/askbot/askbotsite${name}/log"],
  }

  file { "/opt/askbot/askbotsite${name}/askbot":
    ensure  => directory,
    owner   => 'askbot',
    group   => 'www-data',
    mode    => '0664',
    require => File["/opt/askbot/askbotsite${name}"],
  }

  file { "/opt/askbot/askbotsite${name}/askbot/upfiles":
    ensure  => directory,
    owner   => 'askbot',
    group   => 'www-data',
    mode    => '0664',
    require => File["/opt/askbot/askbotsite${name}/askbot"],
  }

  if $ssl_cert_file_contents != '' {
    file { $ssl_cert_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_cert_file_contents,
    }
  }

  if $ssl_key_file_contents != '' {
    file { $ssl_key_file:
      owner   => 'root',
      group   => 'ssl-cert',
      mode    => '0640',
      content => $ssl_key_file_contents,
      require => Package['ssl-cert'],
    }
  }

  if $ssl_chain_file_contents != '' {
    file { $ssl_chain_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_chain_file_contents,
    }
  }
}
