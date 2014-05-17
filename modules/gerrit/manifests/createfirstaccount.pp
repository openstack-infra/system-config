# == gerrit::createfirstaccount
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
# Our goal is to create the first user account with the gerrit2 user credentials.
#  If the first account was already created, then bail and be done with it.
# This is only useful for bootstraping other commands that we'll need for a
#  fully automated gerrit account setup.
#
#

class gerrit::createfirstaccount (
    $gerrit_id  = 'gerrit2',
    $debug_flag = false,
)
{
  include gerrit::params
  include gerrit::pyscripts

  # if the accounts 0 id does not exist, then create it and take it for $gerrit_id
  if($debug_flag)
  {
    $debug_opts = '--loglevel debug'
  }
  else
  {
    $debug_opts = ''
  }

  exec { 'gerrit::createfirstaccount':
            path    => ['/bin', '/usr/bin'],
            command => "python ${::gerrit::params::scripts_home}/createfirstaccount.py ${debug_opts} --ssh_pubkey ${::gerrit::params::gerrit_pub}",
            onlyif  => "python ${::gerrit::params::scripts_home}/createfirstaccount.py --check_exists ${debug_opts}",
            notify  => Service['gerrit'],
            require => File[$::gerrit::params::gerrit_pub],
  }

}
