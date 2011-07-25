import sys
import subprocess
from launchpadlib.launchpad import Launchpad
from launchpadlib.uris import LPNET_SERVICE_ROOT

cachedir = "~/.launchpadlib/cache"
launchpad = Launchpad.login_with('Sync Users', LPNET_SERVICE_ROOT, cachedir)


def get_type(in_type):
    if in_type == "RSA":
        return "ssh-rsa"
    else:
        return "ssh-dsa"

for team_todo in ('openstack-ci-admins', 'openstack-admins'):
    team_underscores = team_todo.replace('-', '_')

    team = launchpad.people[team_todo]
    details = [detail for detail in team.members_details]

    users = []

    with open("manifests/%s_users.pp" % team_underscores, "w") as user_pp:
        user_pp.write("""
class %s_users {
    include sudoers
    """ % team_underscores)
        for detail in details:
            sudo = True
            member = detail.member
            status = detail.status
            if (status == "Approved" or status == "Administrator") \
                and member.is_valid:
                full_name = member.display_name.replace("'", "\\'")
                login_name = member.name
                ssh_keys = "\\n".join(["%s %s %s" % (get_type(key.keytype),
                    key.keytext, key.comment) for key in member.sshkeys])
                ssh_keys = ssh_keys.replace("\n", "\\n")

                for nick in member.irc_nicknames:
                    if nick.network == 'ci.openstack.org':
                        login_name = nick.nickname

                auth_content = "[Launchpad]\\nhost = .launchpad.net\\n" + \
                    "scheme = ssh\\nuser = %s\\n" % member.name

                user_pp.write("""
  group { '%(login_name)s':
    ensure => 'present'
  }

  user { '%(login_name)s':
    ensure => 'present',
    comment => '%(full_name)s',
    home => $operatingsystem ? {
      Darwin => '/Users/%(login_name)s',
      solaris => '/export/home/%(login_name)s',
      default => '/home/%(login_name)s',
    },
    shell => '/bin/bash',
    gid => '%(login_name)s',
    groups => ['wheel','sudo','admin'],
    membership => 'minimum',
  }

  file { '%(login_name)shome':
    name => $operatingsystem ? {
      Darwin => '/Users/%(login_name)s',
      solaris => '/export/home/%(login_name)s',
      default => '/home/%(login_name)s',
    },
    owner => '%(login_name)s',
    group => '%(login_name)s',
    mode => 644,
    ensure => 'directory',
  }


  file { '%(login_name)ssshdir':
    name => $operatingsystem ? {
      Darwin => '/Users/%(login_name)s/.ssh',
      solaris => '/export/home/%(login_name)s/.ssh',
      default => '/home/%(login_name)s/.ssh',
    },
    owner => '%(login_name)s',
    group => '%(login_name)s',
    mode => 700,
    ensure => 'directory',
    require => File['%(login_name)shome'],
  }

  file { '%(login_name)skeys':
    name => $operatingsystem ? {
      Darwin => '/Users/%(login_name)s/.ssh/authorized_keys',
      solaris => '/export/home/%(login_name)s/.ssh/authorized_keys',
      default => '/home/%(login_name)s/.ssh/authorized_keys',
    },
    owner => '%(login_name)s',
    group => '%(login_name)s',
    mode => 640,
    content => "%(ssh_keys)s",
    ensure => 'present',
    require => File['%(login_name)ssshdir'],
  }

  file { '%(login_name)sbashrc':
    name => $operatingsystem ? {
      Darwin => '/Users/%(login_name)s/.bashrc',
      solaris => '/export/home/%(login_name)s/.bashrc',
      default => '/home/%(login_name)s/.bashrc',
    },
    owner => '%(login_name)s',
    group => '%(login_name)s',
    mode => 640,
    source => "/etc/skel/.bashrc",
    replace => 'false',
    ensure => 'present',
  }

  file { '%(login_name)sbash_logout':
    name => $operatingsystem ? {
      Darwin => '/Users/%(login_name)s/.bash_logout',
      solaris => '/export/home/%(login_name)s/.bash_logout',
      default => '/home/%(login_name)s/.bash_logout',
    },
    source => "/etc/skel/.bash_logout",
    owner => '%(login_name)s',
    group => '%(login_name)s',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { '%(login_name)sprofile':
    name => $operatingsystem ? {
      Darwin => '/Users/%(login_name)s/.profile',
      solaris => '/export/home/%(login_name)s/.profile',
      default => '/home/%(login_name)s/.profile',
    },
    source => "/etc/skel/.profile",
    owner => '%(login_name)s',
    group => '%(login_name)s',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { '%(login_name)sbazaardir':
    name => $operatingsystem ? {
      Darwin => '/Users/%(login_name)s/.bazaar',
      solaris => '/export/home/%(login_name)s/.bazaar',
      default => '/home/%(login_name)s/.bazaar',
    },
    owner => '%(login_name)s',
    group => '%(login_name)s',
    mode => 755,
    ensure => 'directory',
    require => File['%(login_name)shome'],
  }


  file { '%(login_name)sbazaarauth':
    name => $operatingsystem ? {
      Darwin => '/Users/%(login_name)s/.bazaar/authentication.conf',
      solaris => '/export/home/%(login_name)s/.bazaar/authentication.conf',
      default => '/home/%(login_name)s/.bazaar/authentication.conf',
    },
    owner => '%(login_name)s',
    group => '%(login_name)s',
    mode => 640,
    content => "%(auth_content)s",
    ensure => 'present',
    require => File['%(login_name)sbazaardir'],
  }

""" % dict(login_name=login_name, full_name=full_name, ssh_keys=ssh_keys,
           member_name=member.name, auth_content=auth_content))

            print "User=%s created" % login_name
        user_pp.write("""
}
  """)
