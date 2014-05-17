# == gerrit::pyscripts
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
# Install scripts on the target machine if they are missing
#
#

class gerrit::pyscripts (
)
{
  include gerrit::params

# if the accounts 0 id already exist, then we're done.  can't continue
  notify{'setup python scripts for gerrit':}
# if the accounts 0 id does not exist, then create it and take it for $gerrit_id

  # create missing folder

  if ! defined(File[$::gerrit::params::scripts_home])
  {
    file { $::gerrit::params::scripts_home:
        ensure  => directory,
        owner   => 'puppet',
        group   => 'puppet',
        mode    => '0755',
        recurse => true,
    }
  }

  file { "${::gerrit::params::scripts_home}/createfirstaccount.py":
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0555',
      source  => 'puppet:///modules/gerrit/scripts/createfirstaccount.py',
      replace => true,
      require => [
                  File["${::gerrit::params::scripts_home}/Colorer.py"],
                  File["${::gerrit::params::scripts_home}/gerrit_common.py"],
                  File["${::gerrit::params::scripts_home}/gen_known_hosts.py"],
      ],
  }

  file { "${::gerrit::params::scripts_home}/gen_known_hosts.py":
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0555',
      source  => 'puppet:///modules/gerrit/scripts/gen_known_hosts.py',
      replace => true,
      require => File[$::gerrit::params::scripts_home],
  }

  file { "${::gerrit::params::scripts_home}/gerrit_common.py":
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0555',
      source  => 'puppet:///modules/gerrit/scripts/gerrit_common.py',
      replace => true,
      require => File[$::gerrit::params::scripts_home],
  }

  file { "${::gerrit::params::scripts_home}/gerrit_runsql.py":
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0555',
      source  => 'puppet:///modules/gerrit/scripts/gerrit_runsql.py',
      replace => true,
      require => File[$::gerrit::params::scripts_home],
  }

  file { "${::gerrit::params::scripts_home}/Colorer.py":
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0555',
      source  => 'puppet:///modules/gerrit/scripts/Colorer.py',
      replace => true,
      require => File[$::gerrit::params::scripts_home],
  }
}
