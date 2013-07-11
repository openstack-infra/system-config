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
# == Define: cgit
#
define cgit::site(
  $gerrit_url = '',
  $cgit_gerrit_ssh_key = '',
) {

  file { '/home/cgit/.ssh/':
    ensure  => directory,
    owner   => 'cgit',
    group   => 'cgit',
    mode    => '0700',
    require => User['cgit'],
  }

  file { '/home/cgit/.ssh/known_hosts':
    owner   => 'cgit',
    group   => 'cgit',
    mode    => '0600',
    content => "${gerrit_url} ${cgit_gerrit_ssh_key}",
    replace => true,
    require => File['/home/cgit/.ssh/']
  }

}

# vim:sw=2:ts=2:expandtab:textwidth=79
