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
# == Class: openstack_project::translations_checksite
#
class openstack_project::translations_checksite (
  $zanata_server = 'openstack',
  $zanata_version = '3.8.1',
  $zanata_cli = '/opt/zanata/zanata-cli-3.8.1/bin/zanata-cli',
  $zanata_url = 'https://translate.openstack.org:443',
  $zanata_server_user,
  $zanata_server_api_key,
  $zanata_project_version = 'master',
  $devstack_branch = 'master',
  $devstack_admin_password,
  $devstack_database_password,
  $devstack_rabbit_password,
  $devstack_service_password,
  $devstack_service_token,
  $devstack_swift_hash,
  $devstack_ssh_pubkey,
  $checksite_sync_hour = '00',
  $checksite_sync_minute = '00',
  $checksite_restack = 0,
  $checksite_restack_hour = '06',
  $checksite_restack_minute = '00',
) {

  apt::source { "archive.ubuntu.com-${lsbdistcodename}-backports":
   location => 'http://archive.ubuntu.com/ubuntu',
   key      => '630239CC130E1A7FD81A27B140976EAF437D05B5',
   repos    => 'main universe multiverse restricted',
   release  => "${lsbdistcodename}-backports"
  }

  class {'::zanata::client':
    version        => $zanata_version,
    server         => $zanata_server,
    server_url     => $zanata_url,
    server_user    => $zanata_server_user,
    server_api_key => $zanata_server_api_key,
    user           => 'stack',
    group          => 'stack',
    homedir        => '/home/stack/',
  }

  class {'::translation_checksite':
    zanata_cli          => $zanata_cli,
    zanata_url          => $zanata_url,
    devstack_dir        => '/home/stack/devstack',
    stack_user          => 'stack',
    revision            => $devstack_branch,
    project_version     => $zanata_project_version,
    admin_password      => $devstack_admin_password,
    database_password   => $devstack_database_password,
    rabbit_password     => $devstack_rabbit_password,
    service_password    => $devstack_service_password,
    service_token       => $devstack_service_token,
    swift_hash          => $devstack_swift_hash,
    devstack_ssh_pubkey => $devstack_ssh_pubkey,
    sync_hour           => $checksite_sync_hour,
    sync_minute         => $checksite_sync_minute,
    restack             => $checksite_restack,
    restack_hour        => $checksite_restack_hour,
    restack_minute      => $checksite_restack_minute,
  }
}
