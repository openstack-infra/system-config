# Copyright (c) 2014 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Puppet maillist provider for mailman mailing lists.
# Based on the 'mailman' package provider in puppet 2.7, except this one
# does not muck with aliases.

require 'puppet/provider/parsedfile'

Puppet::Type.type(:maillist).provide(:noaliasmailman) do
  if [ "CentOS", "RedHat", "Fedora" ].any? { |os|  Facter.value(:operatingsystem) == os }
    commands :list_lists => "/usr/lib/mailman/bin/list_lists", :rmlist => "/usr/lib/mailman/bin/rmlist", :newlist => "/usr/lib/mailman/bin/newlist"
    commands :mailman => "/usr/lib/mailman/mail/mailman"
  else
    # This probably won't work for non-Debian installs, but this path is sure not to be in the PATH.
    commands :list_lists => "list_lists", :rmlist => "rmlist", :newlist => "newlist"
    commands :mailman => "/var/lib/mailman/mail/mailman"
  end

  mk_resource_methods

  # Return a list of existing mailman instances.
  def self.instances
    list_lists('--bare').
      split("\n").
      collect { |line| new(:ensure => :present, :name => line.strip) }
  end

  # Prefetch our list list, yo.
  def self.prefetch(lists)
    instances.each do |prov|
      if list = lists[prov.name] || lists[prov.name.downcase]
        list.provider = prov
      end
    end
  end

  def aliases
  end

  # Create the list.
  def create
    args = []
    if val = @resource[:mailserver]
      args << "--emailhost" << val
    end
    if val = @resource[:webserver]
      args << "--urlhost" << val
    end

    args << self.name
    if val = @resource[:admin]
      args << val
    else
      raise ArgumentError, "Mailman lists require an administrator email address"
    end
    if val = @resource[:password]
      args << val
    else
      raise ArgumentError, "Mailman lists require an administrator password"
    end
    newlist(*args)
  end

  # Delete the list.
  def destroy(purge = false)
    args = []
    args << "--archives" if purge
    args << self.name
    rmlist(*args)
  end

  # Does our list exist already?
  def exists?
    properties[:ensure] != :absent
  end

  # Clear out the cached values.
  def flush
    @property_hash.clear
  end

  # Look up the current status.
  def properties
    if @property_hash.empty?
      @property_hash = query || {:ensure => :absent}
      @property_hash[:ensure] = :absent if @property_hash.empty?
    end
    @property_hash.dup
  end

  # Remove the list and its archives.
  def purge
    destroy(true)
  end

  # Pull the current state of the list from the full list.  We're
  # getting some double entendre here....
  def query
    self.class.instances.each do |list|
      if list.name == self.name or list.name.downcase == self.name
        return list.properties
      end
    end
    nil
  end
end
