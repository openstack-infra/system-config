# == gerrit::security
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
#

class gerrit::security(
) {

  include gerrit::params

  class{'gerrit::createfirstaccount':
    gerrit_id => $::gerrit::params::gerrit_user,
    require   => Class['gerrit'],
  }
  service { 'gerrit':
    ensure    => running,
    enable    => true,
    require   => Class['gerrit::createfirstaccount'],
  }

# Below steps should not require a service restart.

  gerrit_config::create_group{'Project Bootstrappers':
        owner       => 'Administrators',
        member      => $::gerrit::params::gerrit_user,
        description => 'Project creation group',
        isvisible   => true,
        require     => Service['gerrit'],
  } ->
  gerrit_config::create_group{'External Testing Tools':
        owner       => 'Administrators',
        description => 'Verification groupfor +1 / -1 testing',
        isvisible   => true,
  } ->
  gerrit_config::create_group{'Continuous Integration Tools':
        owner       => 'Administrators',
        description => 'CI tools for +2/-2 verification',
        isvisible   => true,
  } ->
  gerrit_config::create_group{'Release Managers':
        owner         => 'Project Bootstrappers',
        description   => 'Release managers',
        isvisible     => true,
  } ->
  gerrit_config::create_group{'Stable Maintainers':
        owner       => 'Project Bootstrappers',
        description => 'Users that maintain stable branches',
        isvisible   => true,
  } ->

# create all batch accounts for gerrit
# Note, if a key has not been stored on the puppet master first, this will fail!
  class {'gerrit::allprojects_acls_setup':
  }
}
