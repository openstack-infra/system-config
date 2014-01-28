# Copyright 2013  OpenStack Foundation
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
# == Define: deploy
#
# deployment tool for laravel framework/php site management
#
define openstackid::deploy (
) {
  $deploy_dirs = [ '/opt/deploy', '/opt/deploy/conf.d' ]

  file { $deploy_dirs:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  file { '/opt/deploy/deploy.sh':
    source  => 'puppet:///modules/openstackid/deploy.sh',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File[$deploy_dirs],
  }

  file { '/opt/deploy/functions':
    source  => 'puppet:///modules/openstackid/functions',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File[$deploy_dirs],
  }

  file { '/opt/deploy/deployrc':
    source  => 'puppet:///modules/openstackid/deployrc',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File[$deploy_dirs],
  }
}