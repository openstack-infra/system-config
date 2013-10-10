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
# deal with url based downloads.
#

require 'net/https'
require 'uri'
require 'digest/md5'
require 'fileutils'

# load local libs
$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__) , ".."))) unless $LOAD_PATH.include?(File.expand_path(File.join(File.dirname(__FILE__) , "..")))

require 'downloader/url/utils'
require 'downloader/url/actions'

Puppet::Type.type(:downloader).provide :url do
  desc "downloads a file from http/https url and does md5 digest check."

  include ::Downloader::Utils
  include ::Downloader::Actions

end
