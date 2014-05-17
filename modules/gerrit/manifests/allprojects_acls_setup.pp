# == gerrit::allprojects_acls_setup
# Copyright 2013 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Setup the default acl's for all projects.
#
#
class gerrit::allprojects_acls_setup (
  $debug_flag     = false,
  $acl_user       = $gerrit::params::gerrit_user,
  $acl_group      = $gerrit::params::gerrit_user,
  $gerritroot     = $::gerrit_home_user_path,
  $review_site    = $::gerrit_home,
  $perms_config   = 'puppet:///modules/gerrit/allprojects_default.project.config',
  $default_groups = 'puppet:///modules/gerrit/default.groups',
)
{
  include gerrit::params

  if($debug_flag)
  {
    $debug_opts = '--loglevel debug'
  }
  else
  {
    $debug_opts = ''
  }

# create folder if missing

  file { "${gerritroot}/workspace":
        ensure  => directory,
        owner   => $acl_user,
        group   => $acl_group,
        mode    => '0755',
        recurse => true,
  }
  file { "${gerritroot}/workspace/All-Projects":
        ensure  => directory,
        owner   => $acl_user,
        group   => $acl_group,
        mode    => '0755',
        recurse => true,
        require => File["${gerritroot}/workspace"],
  }
# checkout project if missing
  exec { 'All-Projects .git init':
        path    => ['/bin', '/usr/bin'],
        command => 'git init',
        cwd     => "${gerritroot}/workspace/All-Projects",
        onlyif  => "test ! -d ${gerritroot}/workspace/All-Projects/.git",
        require => File["${gerritroot}/workspace/All-Projects"],
  }
  exec { 'Add gerrit remote for All-Projects':
        path    => ['/bin', '/usr/bin'],
        command => "git remote add gerrit file://${review_site}/git/All-Projects.git",
        cwd     => "${gerritroot}/workspace/All-Projects",
        onlyif  => 'test $(git remote -v|grep gerrit|wc -l) -le 0',
        require => Exec['All-Projects .git init'],
  }
  exec { 'fetch All-Project head':
        path    => ['/bin', '/usr/bin'],
        command => 'git fetch gerrit +refs/meta/*:refs/remotes/gerrit-meta/*',
        cwd     => "${gerritroot}/workspace/All-Projects",
        require => Exec['Add gerrit remote for All-Projects'],
  }
  exec { 'checkout All-Project head':
        path    => ['/bin', '/usr/bin'],
        command => 'git checkout -b config remotes/gerrit-meta/config',
        cwd     => "${gerritroot}/workspace/All-Projects",
        onlyif  => 'test $(git branch | wc -l) -le 0',
        require => Exec['fetch All-Project head'],
  }

# setup default project config

  file { "${gerritroot}/workspace/All-Projects/project.config":
      ensure  => present,
      owner   => $acl_user,
      group   => $acl_group,
      mode    => '0444',
      source  => $perms_config,
      replace => true,
      require => Exec['checkout All-Project head'],
  }

#setup default groups
  notify{$gerrit::params::gerrit_local_gsql:} ->
  exec { 'get groups json':
        path    => ['/bin', '/usr/bin'],
        command => "${gerrit::params::gerrit_local_gsql} --format JSON -c 'select group_uuid, name from account_groups where not name like \"%-core\" order by group_uuid;' > /tmp/groups.json",
        require => File["${gerritroot}/workspace/All-Projects/project.config"],
  }
  file { "${gerritroot}/workspace/All-Projects/groups":
      ensure  => present,
      owner   => $acl_user,
      group   => $acl_group,
      mode    => '0444',
      source  => $default_groups,
      replace => true,
      require => Exec['get groups json'],
  }
  exec { 'groups json to tab format':
        path    => ['/bin', '/usr/bin'],
        command => "cat /tmp/groups.json | sed 's/\",\"/\":\"/g'|grep '\"row\"'|awk -F '\":\"' '{print \$4\"\t\"\$6}'|sed 's/\"}}\$//g'>> groups",
        cwd     => "${gerritroot}/workspace/All-Projects",
        require => File["${gerritroot}/workspace/All-Projects/groups"],
  }

  exec { 'add All-Project project.config':
        path        => ['/bin', '/usr/bin'],
        command     => 'git add project.config',
        cwd         => "${gerritroot}/workspace/All-Projects",
        onlyif      => 'test $(git diff project.config | wc -l) -gt 0',
        require     => File["${gerritroot}/workspace/All-Projects/project.config"],
        refreshonly => true,
        subscribe   => File["${gerritroot}/workspace/All-Projects/project.config"],
  }

  exec { 'add All-Project groups':
        path        => ['/bin', '/usr/bin'],
        command     => 'git add groups',
        cwd         => "${gerritroot}/workspace/All-Projects",
        onlyif      => 'test $(git diff groups | wc -l) -gt 0',
        require     => Exec['groups json to tab format'],
        refreshonly => true,
        subscribe   => Exec['groups json to tab format']
  }

  exec { 'commit All-Project':
        path        => ['/bin', '/usr/bin'],
        command     => 'git commit -am "puppet run commit to apply default acls on all-projects"',
        cwd         => "${gerritroot}/workspace/All-Projects",
        refreshonly => true,
        onlyif      => 'test $(git status -s|grep "^M" | wc -l) -gt 0',
        require     => [
                        Exec['add All-Project project.config'],
                        Exec['add All-Project groups'],
                      ],
        subscribe   => [
                        Exec['add All-Project project.config'],
                        Exec['add All-Project groups'],
                      ]
  }

  exec { 'push All-Project':
        path        => ['/bin', '/usr/bin'],
        command     => 'git push gerrit HEAD:refs/meta/config',
        cwd         => "${gerritroot}/workspace/All-Projects",
        onlyif      => 'test $(git branch -r --contains $(git rev-parse HEAD) | wc -l) -le 0',
        require     => Exec['commit All-Project'],
  }

}
