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
# common functions to deal with actions.
#
module Downloader
  module Utils
    # get proxy from environment
    def getproxy
      proxy = (ENV['HTTP_PROXY'] == nil)? ENV['http_proxy'] : ENV['HTTP_PROXY']
      if (proxy == nil)
        proxy = (ENV['HTTPS_PROXY'] == nil)? ENV['https_proxy'] : ENV['HTTPS_PROXY']
      end
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
      if uri.scheme.downcase == "https"
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

    # save data to file
    def createfile(fspec, data, options = {})

      open(fspec, "wb") do |file|
        file.write(data)
        file.chmod(self.symbolic_mode_to_int(options[:mode])) if options.has_key?(:mode)
      end
      Puppet.debug "setting ownership"
      if Puppet.features.root?
        owner = (options.has_key?(:owner) == true) ? options[:owner] : nil 
        group = (options.has_key?(:group) == true) ? options[:group] : nil
        FileUtils.chown owner, group, fspec if owner != nil || group != nil
      else
        warnonce "Cannot manage permissions as non-root user."
      end
    end

    # is_number
    def is_numeric?(val)
      begin
        res = true if Float val
      rescue 
        res = false
      end
      return res 
    end

    # convert parameter to boolean
    def to_bool(val)
      
      boolval = val
      boolval = val.to_s if val.class == Symbol
      
      return true if boolval == true || boolval =~ (/(true|t|yes|y|1)$/i)
      return false if boolval == false || boolval =~ (/(false|f|no|n|0)$/i)
      raise ArgumentError.new("invalid value for Boolean: \"#{boolval}\" #{boolval.class}")
      
    end

    # md5digest
    def md5(data)
        return md5 = Digest::MD5.hexdigest( data )
    end

    def getfile_md5(fspec)
      val = nil
      raise ArgumentError.new("missing file: \"#{fspec}\"") unless File.exists?(fspec)
      open(fspec, "r") do |file|
        val = md5( file.read )
      end
      return val
    end

    # Check that we can actually create anything
    def check(fspec)
      basedir = File.dirname(fspec)

      if ! FileTest.exists?(basedir)
        raise Puppet::Error,
          "Can not create #{@resource.title}; parent directory does not exist"
      elsif ! FileTest.directory?(basedir)
        raise Puppet::Error,
          "Can not create #{@resource.title}; #{dirname} is not a directory"
      end
    end

  end
end
  
