# Puppet - Automating Configuration Management.

# Copyright (C) 2005-2012 Puppet Labs Inc
# Copyright 2013 Red Hat, Inc.

# Puppet Labs can be contacted at: info@puppetlabs.com

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

# http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Puppet package provider for Python's `pip3` package management frontend.
# <http://pip.openplans.org/>
#
# Loosely based on the 'pip' package provider in puppet 2.7.
require 'puppet/provider/package'
require 'xmlrpc/client'

Puppet::Type.type(:package).provide :pip3,
  :parent => ::Puppet::Provider::Package do

  desc "Python packages via `python-pip3`."

  has_feature :installable, :uninstallable, :upgradeable, :versionable

  # Parse lines of output from `pip freeze`, which are structured as
  # _package_==_version_.
  def self.parse(line)
    if line.chomp =~ /^([^=]+)==([^=]+)$/
      {:ensure => $2, :name => $1, :provider => name}
    else
      nil
    end
  end

  # Return an array of structured information about every installed package
  # that's managed by `pip` or an empty array if `pip` is not available.
  def self.instances
    packages = []
    execpipe "#{pip3_cmd} freeze" do |process|
      process.collect do |line|
        next unless options = parse(line)
        packages << new(options)
      end
    end
    packages
  end

  # Return structured information about a particular package or `nil` if
  # it is not installed or `pip` itself is not available.
  def query
    self.class.instances.each do |provider_pip|
      return provider_pip.properties if @resource[:name] == provider_pip.name
    end
    return nil
  end

  # Ask the PyPI API for the latest version number.  There is no local
  # cache of PyPI's package list so this operation will always have to
  # ask the web service.
  def latest
    client = XMLRPC::Client.new2("http://pypi.python.org/pypi")
    client.http_header_extra = {"Content-Type" => "text/xml"}
    client.timeout = 10
    result = client.call("package_releases", @resource[:name])
    result.first
  rescue Timeout::Error => detail
    raise Puppet::Error, "Timeout while contacting pypi.python.org: #{detail}";
  end

  # Install a package.  The ensure parameter may specify installed,
  # latest, a version number, or, in conjunction with the source
  # parameter, an SCM revision.  In that case, the source parameter
  # gives the fully-qualified URL to the repository.
  def install
    args = %w{install -q}
    if @resource[:source]
      args << "-e"
      if String === @resource[:ensure]
        args << "#{@resource[:source]}@#{@resource[:ensure]}#egg=#{
          @resource[:name]}"
      else
        args << "#{@resource[:source]}#egg=#{@resource[:name]}"
      end
    else
      case @resource[:ensure]
      when String
        args << "#{@resource[:name]}==#{@resource[:ensure]}"
      when :latest
        args << "--upgrade" << @resource[:name]
      else
        args << @resource[:name]
      end
    end
    lazy_pip *args
  end

  # Uninstall a package.  Uninstall won't work reliably on Debian/Ubuntu
  # unless this issue gets fixed.
  # <http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=562544>
  def uninstall
    lazy_pip "uninstall", "-y", "-q", @resource[:name]
  end

  def update
    install
  end

  # Execute a `pip` command.  If Puppet doesn't yet know how to do so,
  # try to teach it and if even that fails, raise the error.
  private
  def lazy_pip(*args)
    pip3 *args
  rescue NoMethodError => e
    self.class.commands :pip => pip3_cmd
    pip *args
  end

  def self.pip3_cmd
    ['/usr/bin/python3-pip', '/usr/bin/pip3', '/usr/bin/pip-3.2', '/usr/bin/pip-3.3'].each do |p|
      return p if File.exist?(p)
    end
    raise Puppet::Error, "Unable to find pip3 binary.";
  end

  def pip3_cmd
    return self.class.pip3_cmd
  end

end
