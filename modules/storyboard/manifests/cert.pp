# Copyright (c) 2014 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

# == Class: storyboard::cert
#
# This module sets up the SSL certificate for storyboard, sourcing the content of the
# certificates either from a file or from a string. If included,
# it will be automatically detected within storyboard::application and the
# application will be hosted over https rather than http.
#
class storyboard::cert (
  $ssl_cert_file    = undef,
  $ssl_cert_content = undef,
  $ssl_cert         = '/etc/ssl/certs/storyboard.pem',

  $ssl_key_file     = undef,
  $ssl_key_content  = undef,
  $ssl_key          = '/etc/ssl/private/storyboard.key',

  $ssl_ca_file      = undef,
  $ssl_ca_content   = undef,
  $ssl_ca           = undef, # '/etc/ssl/certs/ca.pem'
) {

  if $ssl_cert_file != undef {
    file { $ssl_cert:
      owner   => 'root',
      group   => 'ssl-cert',
      mode    => '0640',
      source  => $ssl_cert_file,
      before  => Class['storyboard::application'],
      notify  => Class['storyboard::application'],
    }
  }
  elsif $ssl_cert_content != undef {
    file { $ssl_cert:
      owner   => 'root',
      group   => 'ssl-cert',
      mode    => '0640',
      content => $ssl_cert_content,
      before  => Class['storyboard::application'],
      notify  => Class['storyboard::application'],
    }
  }
  else {
    fail('When including storyboard::cert, you must define either $ssl_cert_file or $ssl_cert_content')
  }

  if $ssl_key_file != undef {
    file { $ssl_key:
      owner   => 'root',
      group   => 'ssl-cert',
      mode    => '0640',
      source  => $ssl_key_file,
      before  => Class['storyboard::application'],
      notify  => Class['storyboard::application'],
    }
  }
  elsif $ssl_key_content != undef {
    file { $ssl_key:
      owner   => 'root',
      group   => 'ssl-cert',
      mode    => '0640',
      content => $ssl_key_content,
      before  => Class['storyboard::application'],
      notify  => Class['storyboard::application'],
    }
  }
  else {
    fail('When including storyboard::cert, you must define either $ssl_key_file or $ssl_key_content')
  }

  # CA file needs special treatment, since we want the path variable
  # to be undef in some cases.
  if ($ssl_ca_file != undef or $ssl_ca_content != undef) and $ssl_ca == undef {
    $ssl_ca = '/etc/ssl/certs/storyboard.ca.pem'
  }

  if $ssl_ca_file != undef {
    file { $ssl_ca:
      owner   => 'root',
      group   => 'ssl-cert',
      mode    => '0640',
      source  => $ssl_ca_file,
      before  => Class['storyboard::application'],
      notify  => Class['storyboard::application'],
    }
  }
  elsif $ssl_ca_content != undef {
    file { $ssl_ca:
      owner   => 'root',
      group   => 'ssl-cert',
      mode    => '0640',
      content => $ssl_ca_content,
      before  => Class['storyboard::application'],
      notify  => Class['storyboard::application'],
    }
  }
}