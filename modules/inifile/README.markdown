[![Build Status](https://travis-ci.org/puppetlabs/puppetlabs-inifile.png?branch=master)](https://travis-ci.org/puppetlabs/puppetlabs-inifile)

# INI-file module #

This module provides resource types for use in managing INI-style configuration
files.  The main resource type is `ini_setting`, which is used to manage an
individual setting in an INI file.  Here's an example usage:

    ini_setting { "sample setting":
      ensure  => present,
      path    => '/tmp/foo.ini',
      section => 'foo',
      setting => 'foosetting',
      value   => 'FOO!',
    }

A supplementary resource type is `ini_subsetting`, which is used to manage
settings that consist of several arguments such as

    JAVA_ARGS="-Xmx192m -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/var/log/pe-puppetdb/puppetdb-oom.hprof "

    ini_subsetting {'sample subsetting':
      ensure  => present,
      section => '',
      key_val_separator => '=',
      path => '/etc/default/pe-puppetdb',
      setting => 'JAVA_ARGS',
      subsetting => '-Xmx',
      value   => '512m',
    }

## implementing child providers:


The ini_setting class can be overridden by child providers in order to implement the management of ini settings for a specific configuration file.

In order to implement this, you will need to specify your own Type (as shown below). This type needs to implement a namevar (name), and a property called value:


  example:

    #my_module/lib/puppet/type/glance_api_config.rb
    Puppet::Type.newtype(:glance_api_config) do
      ensurable
      newparam(:name, :namevar => true) do
        desc 'Section/setting name to manage from glance-api.conf'
        # namevar should be of the form section/setting
        newvalues(/\S+\/\S+/)
      end
      newproperty(:value) do
        desc 'The value of the setting to be defined.'
        munge do |v|
          v.to_s.strip
        end
      end
    end

This type also must have a provider that utilizes the ini_setting provider as its parent:

  example:

    # my_module/lib/puppet/provider/glance_api_config/ini_setting.rb
    Puppet::Type.type(:glance_api_config).provide(
      :ini_setting,
      # set ini_setting as the parent provider
      :parent => Puppet::Type.type(:ini_setting).provider(:ruby)
    ) do
      # implement section as the first part of the namevar
      def section
        resource[:name].split('/', 2).first
      end
      def setting
        # implement setting as the second part of the namevar
        resource[:name].split('/', 2).last
      end
      # hard code the file path (this allows purging)
      def self.file_path
        '/etc/glance/glance-api.conf'
      end
    end


Now, the individual settings of the /etc/glance/glance-api.conf file can be managed as individual resources:

    glance_api_config { 'HEADER/important_config':
      value => 'secret_value',
    }

Provided that self.file_path has been implemented, you can purge with the following puppet syntax:

    resources { 'glance_api_config'
      purge => true,
    }

If the above code is added, then the resulting configured file will only contain lines implemented as Puppet resources


## A few noteworthy features:

 * The module tries *hard* not to manipulate your file any more than it needs to.
   In most cases, it should leave the original whitespace, comments, ordering,
   etc. perfectly intact.
 * Supports comments starting with either '#' or ';'.
 * Will add missing sections if they don't exist.
 * Supports a "global" section (settings that go at the beginning of the file,
   before any named sections) by specifying a section name of "".

