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
# type to deal with file downloads
#
require 'puppet/util/symbolic_file_mode'
include Puppet::Util::SymbolicFileMode

Puppet::Type.newtype(:downloader) do

  @doc = %q{ Downloads a file by url to destination location and does an md5
            check of the file.

  By default we will read HTTP_PROXY or HTTPS_PROXY for proxy servers from
  the environment.

  Certificate check on https urls is always disabled and not implemented.

  Examples:

  create a file owned by puppet and set permissions.

  downloader {'https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py':
              ensure          => present,
              path            => '/var/lib/python-install/ez_setup.py',
              md5             => '6cbf71df4921efdd84a43ed8bc8ee4f7',
              owner           => 'puppet',
              group           => 'puppet',
              mode            => 755,
              replace         => false,
              provider        => url,
            }
            
  downloader {'https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py':
              ensure          => present,
              path            => '/var/lib/python-install/ez_setup.py',
              md5             => '6cbf71df4921efdd84a43ed8bc8ee4f7',
              replace         => false,
              provider        => url,
            }

  install without md5 check
  downloader {'https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py':
              ensure          => present,
              path            => '/var/lib/python-install/ez_setup.py',
              provider        => url,
            }

  remove the file
  downloader {'https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py':
              ensure          => absent,
              path            => '/var/lib/python-install/ez_setup.py',
            }
      }

  ensurable

  newparam(:name) do
    desc "name of the url."
  end

  newparam(:path) do
    desc "full path to destination location of the file, this will be a file."
  end

  newparam(:md5) do
    desc "md5 digest of the file."
  end

  newparam(:replace) do
    desc "remove destination if exist before download."
    newvalues(:true, :false)
    aliasvalue(:yes, :true)
    aliasvalue(:no, :false)
    defaultto :true
  end

  newparam(:mode) do
    desc "should be the target file mode."
    validate do |value|
      unless value.nil? or self.valid_symbolic_mode?(value)
        raise Puppet::Error, "The file mode specification is invalid: #{value.inspect}"
      end
    end
  end

  newparam(:group) do
    desc "should be the group for the file."
  end

  newparam(:owner) do
    desc "should be the owner of the file."
  end

end

