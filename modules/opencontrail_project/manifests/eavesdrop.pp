# Eavesdrop server

class opencontrail_project::eavesdrop (
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
) {
  class { 'opencontrail_project::server':
    iptables_public_tcp_ports => [80],
    sysadmins                 => $sysadmins
  }
  include apache
  include meetbot

  $vhost_extra = '
  <Location /alert>
    Header set Access-Control-Allow-Origin "*"
  </Location>
  '

  meetbot::site { 'opencontrail':
    nick        => 'opencontrail',
    nickpass    => $nickpass,
    network     => 'FreeNode',
    server      => 'chat.freenode.net:7000',
    use_ssl     => 'True',
    vhost_extra => $vhost_extra,
    channels    => [
        '#heat',
        '#murano',
        '#opencontrail',
        '#opencontrail-ceilometer',
        '#opencontrail-climate',
        '#opencontrail-dev',
        '#opencontrail-dns',
        '#opencontrail-infra',
        '#opencontrail-ironic',
        '#opencontrail-keystone',
        '#opencontrail-marconi',
        '#opencontrail-meeting',
        '#opencontrail-meeting-alt',
        '#opencontrail-meeting-3',
        '#opencontrail-neutron',
        '#opencontrail-qa',
        '#opencontrail-relmgr-office',
        '#opencontrail-swift',
        '#opencontrail-trove',
        '#savanna',
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

  file { '/srv/meetbot-opencontrail/alert':
    ensure  => link,
    target  => '/var/lib/statusbot/www',
    require => Class['statusbot'],
  }

  a2mod { 'headers':
    ensure => present,
  }
}
