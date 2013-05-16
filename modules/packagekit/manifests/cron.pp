# Copyright 2013 Red Hat, Inc.
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
# Class: packagekit::cron
#
class packagekit::cron(
  $package_ensure = present,
  $enabled = 'yes',
  $check_only = 'no',
  $mailto = false,
  $system_name = false
) inherits packagekit {

  include packagekit::params

  package { $::packagekit::params::cron_package:
    ensure => $package_ensure,
  }

  file { $::packagekit::params::cron_config_file:
    ensure  => present,
    content => template("${module_name}/packagekit-background.erb"),
    mode    => '0644',
    group   => 'root',
    owner   => 'root',
    replace => true,
    require => Package[$::packagekit::params::cron_package],
  }

}
