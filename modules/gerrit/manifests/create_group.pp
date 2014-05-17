# == gerrit::create_group
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
# create gerrit group
#  pp -e "gerrit::create_group{'test':}"

define gerrit::create_group (
  $group_name  = $title,
  $owner       = undef,
  $member      = undef,
  $description = undef,
  $isvisible   = false,
  $debug_flag  = false,
  $include_group = undef,
)
{
  include gerrit::params

  if $owner == undef
  {
    $owner_opt = ''
  } else
  {
    $owner_opt = "--owner \"'${owner}'\""
  }
  if $member == undef
  {
    $member_opt = ''
  } else
  {
    $member_opt = "--member \"'${member}'\""
  }
  if $description == undef
  {
    $description_opt = ''
  } else
  {
    $description_opt = "--description \"'${description}'\""
  }
  if $include_group == undef
  {
    $include_group_opt = ''
  } else
  {
    $include_group_opt = "--group \"'${include_group}'\""
  }
  if $isvisible == false
  {
    $visible_opt = ''
  } else
  {
    $visible_opt = '--visible-to-all'
  }
  # otherwise we should fail
  # only run if the account exist, value returns 1
  exec { "check for gerrit init ${group_name}":
            path    => ['/bin', '/usr/bin'],
            command => 'echo \'continue with execution of group checks\'',
            onlyif  => "test \$(python ${gerrit::params::scripts_home}/createfirstaccount.py --check_exists ${debug_flag} > /dev/null 2<&1;echo $?) = 1",
  }

  exec { "create group ${group_name}":
            path    => ['/bin', '/usr/bin'],
            command => "echo 'create group ${group_name}';${gerrit::params::gerrit_ssh} gerrit create-group ${owner_opt} ${member_opt} ${description_opt} ${include_group_opt} ${visible_opt} \"'${group_name}'\"",
            onlyif  => "test \$(${gerrit::params::gerrit_ssh} gerrit ls-groups |grep '${group_name}' > /dev/null 2<&1;echo $?) = 1",
            require => Exec["check for gerrit init ${group_name}"],
  }
}
