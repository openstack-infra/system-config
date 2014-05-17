# == gerrit::gerrit_home
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

Facter.add("gerrit_home") do
  confine :kernel => "Linux"
  setcode do
    if File.exist? "/etc/default/gerritcodereview"
      #the string to look for and the path should change depending on the system to discover
      home = open('/etc/default/gerritcodereview').grep(/GERRIT_SITE/)
      starting = home[0].index('=') + 1
      ending = home[0][0]
      home = home[0][starting..ending]
      home.gsub! "\n", ""
      Facter::Util::Resolution.exec("echo #{home}")
    else
      home = Facter.value('gerrit_home_user_path')
      if File.exist? "#{home}/review_site"
        Facter::Util::Resolution.exec("echo #{home}/review_site")
      else
        Facter::Util::Resolution.exec("echo")  # gerrit doesn't exist here
      end
    end
  end
end
