# Copyright 2013 Thierry Carrez
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
# == Define: releasestatus
#
define releasestatus::site(
  $git_url = '',
  $httproot = '',
) {

  file { '/var/lib/releasestatus/config.yaml':
    mode    => '0444',
    source  => 'puppet:///modules/releasestatus/config.yaml'
  }

  file {'/var/lib/releasestatus/releasestatus':
    ensure  => directory,
    owner   => 'releasestatus',
    group   => 'releasestatus',
    mode    => '0755',
    require => File['/var/lib/releasestatus/'],
  }

  vcsrepo { '/var/lib/releasestatus/releasestatus':
    ensure   => latest,
    provider => git,
    source   => $git_url,
    revision => 'master',
  }

  file { $httproot:
    ensure  => directory,
    owner   => 'releasestatus',
    group   => 'releasestatus',
    mode    => '0755',
    source  => '/var/lib/releasestatus/releasestatus/static',
    recurse => remote,
  }

  cron { 'update releasestatus':
    command => "python /var/lib/releasestatus/releasestatus/releasestatus.py /var/lib/releasestatus/config.yaml > ${httproot}/new.html && mv ${httproot}/new.html ${httproot}/index.html",
    minute  => '*/20',
    user    => 'releasestatus',
  }

}

# vim:sw=2:ts=2:expandtab:textwidth=79
