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
class openstack_project::ipsilon_prod (
  $sysadmins = [],
  $ipsilon_db_password,
  $ipsilon_db_hostname,
  $ssl_cert_file_contents,
  $ssl_key_file_contents,
  $ssl_chain_file_contents,
  $ssl_cert_file = '/etc/ssl/certs/idp.openstackid.org.pem',
  $ssl_key_file = '/etc/ssl/private/idp.openstackid.org.key',
  $ssl_chain_file = '/etc/ssl/certs/intermediate.pem',
) {

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
    sysadmins                 => $sysadmins,
  }

  class { 'ipsilon':
    ipsilon_db_password     => $ipsilon_db_password,
    ipsilon_db_hostname     => $ipsilon_db_hostname,
    ssl_cert_file_contents  => $ssl_cert_file_contents,
    ssl_key_file_contents   => $ssl_key_file_contents,
    ssl_chain_file_contents => $ssl_chain_file_contents,
    ssl_cert_file           => $ssl_cert_file,
    ssl_key_file            => $ssl_key_file,
    ssl_chain_file          => $ssl_chain_file,
  }
}
