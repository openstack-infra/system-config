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
# downloader actions
#
module Downloader
  module Actions
    # download the file when it needs to be downloaded.
    def create
      check(@resource[:path])
      data = self.openurl(@resource[:name])
      data_md5 = self.md5(data)
      return if @resource[:md5] == nil
      unless data_md5 == @resource[:md5]
        Puppet.debug "download from #{@resource[:name]} does not match #{@resource[:md5]}"
        raise Puppet::Error, "download has md5 of #{data_md5}"
      end
      options = {}
      options[:group] = @resource[:group] if @resource[:group] != nil
      options[:owner] = @resource[:owner] if @resource[:owner] != nil
      options[:mode]  = @resource[:mode]  if @resource[:mode] != nil
      createfile(@resource[:path], data, options)
    end

  # remove the file if it exist
    def destroy
      File.unlink(@resource[:path])
      Puppet.debug "deleted file #{@resource[:path]}"
    end

  # check if the file exist, unless it's replaced.
    def exists?
      Puppet.debug "check if installed: #{@resource[:path]}"
      return false if self.to_bool(@resource[:replace]) && @resource[:ensure] != :absent
      if File.exists?(@resource[:path])
          return true if @resource[:md5] == nil
          Puppet.debug "checking against md5 #{@resource[:md5]}"
          path_md5 = self.getfile_md5(@resource[:path])
          Puppet.debug "md5 for installed file is #{path_md5}"
          return true if @resource[:md5] == path_md5
      end 
      Puppet.debug "file not installed #{@resource[:path]}"
      return false
    end
  end
end
  
