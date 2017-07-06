# Eavesdrop server

class openstack_project::eavesdrop (
  $nickpass = '',
  $statusbot_nick = '',
  $statusbot_password = '',
  $statusbot_server = '',
  $statusbot_channels = '',
  $statusbot_auth_nicks = '',
  $statusbot_wiki_user = '',
  $statusbot_wiki_password = '',
  $statusbot_wiki_url = '',
  $statusbot_wiki_pageid = '',
  $statusbot_wiki_successpageid = '',
  $statusbot_irclogs_url = '',
  $statusbot_twitter = undef,
  $statusbot_twitter_key = '',
  $statusbot_twitter_secret = '',
  $statusbot_twitter_token_key = '',
  $statusbot_twitter_token_secret = '',
  $accessbot_nick = '',
  $accessbot_password = '',
  $project_config_repo = '',
  $meetbot_channels = [],
  $ptgbot_nick = '',
  $ptgbot_password = '',
) {
  include ::httpd
  include meetbot

  $vhost_extra = '
  <Location /alert>
    Header set Access-Control-Allow-Origin "*"
  </Location>
  '

  meetbot::site { 'openstack':
    nick         => 'openstack',
    nickpass     => $nickpass,
    network      => 'FreeNode',
    server       => 'chat.freenode.net:7000',
    use_ssl      => 'True',
    vhost_extra  => $vhost_extra,
    manage_index => false,
    channels     => $meetbot_channels,
  }

  class { 'statusbot':
    nick                 => $statusbot_nick,
    password             => $statusbot_password,
    server               => $statusbot_server,
    channels             => $statusbot_channels,
    auth_nicks           => $statusbot_auth_nicks,
    wiki_user            => $statusbot_wiki_user,
    wiki_password        => $statusbot_wiki_password,
    wiki_url             => $statusbot_wiki_url,
    wiki_pageid          => $statusbot_wiki_pageid,
    wiki_successpageid   => $statusbot_wiki_successpageid,
    irclogs_url          => $statusbot_irclogs_url,
    twitter              => $statusbot_twitter,
    twitter_key          => $statusbot_twitter_key,
    twitter_secret       => $statusbot_twitter_secret,
    twitter_token_key    => $statusbot_twitter_token_key,
    twitter_token_secret => $statusbot_twitter_token_secret,
  }

  file { '/srv/meetbot-openstack/alert':
    ensure  => link,
    target  => '/var/lib/statusbot/www',
    require => Class['statusbot'],
  }

  if ! defined(Httpd::Mod['headers']) {
    httpd::mod { 'headers':
        ensure => present,
    }
  }

  class { 'project_config':
    url  => $project_config_repo,
  }

  class { 'accessbot':
    nick          => $accessbot_nick,
    password      => $accessbot_password,
    server        => $statusbot_server,
    channel_file  => $::project_config::accessbot_channels_yaml,
    require       => $::project_config::config_dir,
  }

  # Needed to allow Jenkins jobs to publish meeting info to
  # the eavesdrop server.
  include openstack_project
  class { 'jenkins::jenkinsuser':
    ssh_key     => $openstack_project::jenkins_ssh_key,
  }

  file { '/srv/yaml2ical':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    require => User['jenkins'],
  }

  file { '/srv/yaml2ical/calendars':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    require => File['/srv/yaml2ical'],
  }

  file { '/srv/meetbot-openstack/index.html':
    ensure  => link,
    target  => '/srv/yaml2ical/index.html',
    require => File['/srv/yaml2ical'],
  }

  file { '/srv/meetbot-openstack/irc-meetings.ical':
    ensure  => link,
    target  => '/srv/yaml2ical/irc-meetings.ical',
    require => File['/srv/yaml2ical'],
  }

  file { '/srv/meetbot-openstack/calendars/':
    ensure  => link,
    target  => '/srv/yaml2ical/calendars/',
    require => File['/srv/yaml2ical'],
  }

  class { 'ptgbot':
    nick     => $ptgbot_nick,
    password => $ptgbot_password,
    channel  => '#openstack-ptg',
  }

}
