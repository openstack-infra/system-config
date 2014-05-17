# == gerrit::gerrit_java_home
# Copyright 2013 OpenStack Foundation.
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

Facter.add("gerrit_java_home") do
  confine :kernel => "Linux"
  setcode do
    gerrit_config = Facter.value('gerrit_config')
    if File.exist? gerrit_config
      Facter::Util::Resolution.exec("git config -f #{gerrit_config} --get container.javaHome")
    else
      Facter::Util::Resolution.exec("echo")  # gerrit doesn't exist here
    end
  end
end
