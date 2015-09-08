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
  $accessbot_nick = '',
  $accessbot_password = '',
  $project_config_repo = '',
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
    channels     => [
        '#akanda',
        '#cloudkitty',
        '#dox',
        '#heat',
        '#kolla',
        '#magnetodb',
        '#murano',
        '#openstack',
        '#openstack-ansible',
        '#openstack-api',
        '#openstack-app-catalog',
        '#openstack-barbican',
        '#openstack-blazar',
        '#openstack-ceilometer',
        '#openstack-chef',
        '#openstack-cinder',
        '#openstack-cloudpulse',
        '#openstack-community',
        '#openstack-containers',
        '#openstack-cue',
        '#openstack-defcore',
        '#openstack-dev',
        '#openstack-diversity',
        '#openstack-dns',
        '#openstack-doc',
        '#openstack-fr',
        '#openstack-freezer',
        '#openstack-glance',
        '#openstack-gslb',
        '#openstack-heat-translator',
        '#openstack-horizon',
        '#openstack-i18n',
        '#openstack-infra',
        '#openstack-infra-incident',
        '#openstack-ironic',
        '#openstack-keystone',
        '#openstack-ko',
        '#openstack-lbaas',
        '#openstack-manila',
        '#openstack-meeting',
        '#openstack-meeting-alt',
        '#openstack-meeting-3',
        '#openstack-meeting-4',
        '#openstack-mistral',
        '#openstack-monasca',
        '#openstack-neutron',
        '#openstack-neutron-ovn',
        '#openstack-neutron-release',
        '#openstack-nova',
        '#openstack-operators',
        '#openstack-oslo',
        '#openstack-qa',
        '#openstack-rally',
        '#openstack-rating',
        '#openstack-relmgr-office',
        '#openstack-sahara',
        '#openstack-sdks',
        '#openstack-searchlight',
        '#openstack-security',
        '#openstack-sprint',
        '#openstack-stable',
        '#openstack-swift',
        '#openstack-tailgate',
        '#openstack-trove',
        '#openstack-zaqar',
        '#puppet-openstack',
        '#refstack',
        '#senlin',
        '#storyboard',
        '#tripleo',
    ],
  }

  class { 'statusbot':
    nick          => $statusbot_nick,
    password      => $statusbot_password,
    server        => $statusbot_server,
    channels      => $statusbot_channels,
    auth_nicks    => $statusbot_auth_nicks,
    wiki_user     => $statusbot_wiki_user,
    wiki_password => $statusbot_wiki_password,
    wiki_url      => $statusbot_wiki_url,
    wiki_pageid   => $statusbot_wiki_pageid,
  }

  file { '/srv/meetbot-openstack/alert':
    ensure  => link,
    target  => '/var/lib/statusbot/www',
    require => Class['statusbot'],
  }

  httpd_mod { 'headers':
    ensure => present,
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
}
