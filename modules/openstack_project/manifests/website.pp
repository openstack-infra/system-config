# Copyright 2017 Red Hat, Inc.
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

define openstack_project::website (
  $aliases = undef,
  $volume_name = undef,
  $ssl_cert = undef,
  $ssl_key = undef,
  $ssl_intermediate = undef,
  $template = 'openstack_project/website.vhost.erb',
  $docroot = undef,
) {

  $afs_root = '/afs/openstack.org/'
  if $volume_name == undef {
    # Default to volume name matching vhost name
    $volume_name_ = $name
  } else {
    $volume_name_ = $volume_name
  }

  if $docroot == undef {
     $docroot_ = "${afs_root}/project/${volume_name_}/www"
  } else {
     $docroot_ = $docroot
  }

  ::httpd::vhost { $name:
    serveraliases => $aliases,
    port          => 443, # Is required despite not being used.
    docroot       => $docroot_,
    priority      => '50',
    template      => $template,
    require       => [File["/etc/ssl/certs/${name}.pem"],
                      File["/etc/ssl/private/${name}.key"],
                      File["/etc/ssl/certs/${name}_intermediate.pem"]],
  }

  file { "/etc/ssl/certs/${name}.pem":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $ssl_cert,
    require => File['/etc/ssl/certs'],
  }

  file { "/etc/ssl/private/${name}.key":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => $ssl_key,
    require => File['/etc/ssl/private'],
  }

  file { "/etc/ssl/certs/${name}_intermediate.pem":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $ssl_intermediate,
    require => File['/etc/ssl/certs'],
  }
}
