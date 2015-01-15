# Eavesdrop server

class openstack_project::eavesdrop (
  $nickpass = '',
  $sysadmins = [],
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
  $ssh_user_config_options = {},
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
    sysadmins                 => $sysadmins,
    ssh_user_config_options   => $ssh_user_config_options,
  }
  include apache
  include meetbot

  $vhost_extra = '
  <Location /alert>
    Header set Access-Control-Allow-Origin "*"
  </Location>
  '

  meetbot::site { 'openstack':
    nick        => 'openstack',
    nickpass    => $nickpass,
    network     => 'FreeNode',
    server      => 'chat.freenode.net:7000',
    use_ssl     => 'True',
    vhost_extra => $vhost_extra,
    channels    => [
        '#dox',
        '#heat',
        '#magnetodb',
        '#murano',
        '#openstack',
        '#openstack-barbican',
        '#openstack-blazar',
        '#openstack-ceilometer',
        '#openstack-chef',
        '#openstack-cinder',
        '#openstack-community',
        '#openstack-containers',
        '#openstack-dev',
        '#openstack-dns',
        '#openstack-fr',
        '#openstack-horizon',
        '#openstack-infra',
        '#openstack-ironic',
        '#openstack-keystone',
        '#openstack-lbaas',
        '#openstack-meeting',
        '#openstack-meeting-alt',
        '#openstack-meeting-3',
        '#openstack-meeting-4',
        '#openstack-monasca',
        '#openstack-neutron',
        '#openstack-operators',
        '#openstack-oslo',
        '#openstack-qa',
        '#openstack-rating',
        '#openstack-relmgr-office',
        '#openstack-sahara',
        '#openstack-sdks',
        '#openstack-security',
        '#openstack-sprint',
        '#openstack-swift',
        '#openstack-trove',
        '#openstack-zaqar',
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

  a2mod { 'headers':
    ensure => present,
  }

  class { 'project_config':
    url  => $project_config_repo,
  }
  Ssh_user_config['root'] -> Class['project_config']

  class { 'accessbot':
    nick          => $accessbot_nick,
    password      => $accessbot_password,
    server        => $statusbot_server,
    channel_file  => $::project_config::accessbot_channels_yaml,
    require       => $::project_config::config_dir,
  }
}
