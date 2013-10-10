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

# Puppet package provider for Python's `pip` package management frontend.
# <http://pip-installer.org/>
#
# Loosely based on the 'pip' package provider in puppet 2.7.
require 'puppet/provider/package'
require 'json'                      if Puppet.features.json?  
require 'net/https'
require 'uri'


Puppet::Type.type(:package).provide :pip2,
  :parent => ::Puppet::Provider::Package do

  desc "Python packages via `pip` from pip-installer.org"
  confine :feature => :json
  has_feature :installable, :uninstallable, :upgradeable, :versionable

# get pip proxy option
  def pipproxyarg
    proxy = getproxy
    return ((proxy != nil) ? ["--proxy", proxy] : [])
  end

  # get proxy from environment
  def getproxy
    proxy = (ENV['HTTP_PROXY'] == nil)? ENV['http_proxy'] : ENV['HTTP_PROXY']
    return proxy
  end

  # get proxy settings from environment variables we expect
  #
  def getproxyuri
     proxy = self.getproxy
     proxy_uri = (proxy != nil )? URI.parse(proxy) : nil
     return proxy_uri
  end

  # open a url and return the data
  def openurl(url)
    data = nil
    uri = URI.parse(url)
    proxy_uri = self.getproxyuri
    http = (proxy_uri != nil) ? Net::HTTP.new(uri.host, uri.port, proxy_uri.host, proxy_uri.port) : Net::HTTP.new(uri.host, uri.port)
    if uri.scheme == "https"
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    http.start {
      http.request_get(uri.path) {|res|
        data = res.body
      }
    }
    return data
  end

  # parse json from url data
  def open_jsonurl(url)
    data = self.openurl(url)
    if data != '' and data != nil
      json = JSON.parse(data)
      if json.has_key? 'error_messages'
        raise Puppet::Error, 'Error retrieving url data: ' + json['error_messages'].to_s()
      end
      return json
    else
      return nil
    end
  end

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
    execpipe "#{pip2_cmd} freeze" do |process|
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
    url = "https://pypi.python.org/pypi/#{URI.encode(@resource[:name])}/json"
    result = self.open_jsonurl(url)
    result['info']['version'] if result != nil
  rescue Timeout::Error => detail
    raise Puppet::Error, "Error in contacting pypi.python.org: #{detail}"
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
    args << pipproxyarg
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
# we use util.rb form puppet package to run platform specific command
  def lazy_pip(*args)
    pip2 *args  
  rescue NoMethodError => e
    self.class.commands :pip => pip2_cmd
    pip *args
  end

# look for pip executable
  def self.pip2_cmd
    ['/usr/local/bin/pip', '/usr/bin/pip', which('pip')].each do |p|
      return p if File.exist?(p)
    end
    raise Puppet::Error, "Unable to find pip binary."
  end

# used above in execpipes
  def pip2_cmd
    return self.class.pip2_cmd
  end

end
