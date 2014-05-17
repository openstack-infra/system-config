# Class: gerrit::params
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

class gerrit::params {
  case $::osfamily {
    'Debian': {
      if ($::gerrit_user == UNDEF or $::gerrit_user == '')
      {
        $gerrit_user = 'gerrit2' # We default to gerrit2 when gerrit is not yet installed.
      } else
      {
        $gerrit_user = $::gerrit_user
      }

      $gerrit_home_upath = $::gerrit_home_user_path
      $gerrit_ssh_home   = "${gerrit_home_upath}/.ssh"
      $gerrit_port       = 29418        #TODO: turn into facters
      $gerrit_host       = 'localhost'  #TODO: turn into facters
      $gerrit_pem        = "${gerrit_ssh_home}/id_rsa"
      $gerrit_pub        = "${gerrit_ssh_home}/id_rsa.pub"
      $ssh_cmd           = "ssh -i ${gerrit_pem}"
      $gerrit_com        = "-p ${gerrit_port} ${gerrit_user}@${gerrit_host}"
      $gerrit_ssh        = "${ssh_cmd} ${gerrit_com}"
      $gerrit_local_gsql = "${::gerrit_java_home}/bin/java -jar ${::gerrit_home}/bin/gerrit.war gsql -d ${::gerrit_home}"
      $gerrit_ssh_gsql   = "${gerrit::params::gerrit_ssh} gerrit gsql"
      $scripts_home      = '/var/lib/gerrit_scripts'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily}
            The 'gerrit' module only supports osfamily Debian.")
    }
  }
}
