# Copyright 2014 Red Hat Inc.
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
# Class: yum::repo
#
define yum::repo (
  $description = '',
  $enabled = 0,
  $gpgcheck = 0,
  $baseurl = absent,
  $mirrorlist = absent,
  $cron_hour = 2,
  $cron_minute = 0,
) {

  include 'yum'

  yumrepo { $name:
    name        => $name,
    descr       => $description,
    enabled     => $enabled,
    gpgcheck    => $gpgcheck,
    baseurl     => $baseurl,
    mirrorlist  => $mirrorlist
  }

  cron { "reposync ${name}":
    command => "/usr/bin/reposync -r ${name} -p ${yum::repos_dir}; /bin/createrepo -c /tmp/${name} ${yum::repos_dir}/${name}",
    hour    => $cron_hour,
    minute  => $cron_minute
  }

}
