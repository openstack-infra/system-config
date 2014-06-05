# OpenStack StoryBoard Module

Michael Krotscheck <krotscheck@gmail.com>

This module manages and installs OpenStack StoryBoard. It can be installed
either as a standalone instance with all dependencies included, or
buffet-style per component.

# Quick Start

To install StoryBoard and configure it with sane defaults, include the
following in your site.pp file:

    node default {
    	include storyboard
	}

# Configuration

The StoryBoard puppet module is separated into individual components which
StoryBoard needs to run. These can either be installed independently with
their own configurations, or with the centralized configuration provided by
the storyboard module. For specific configuration options, please see the
appropriate section.

## ::storyboard
A module that installs a standalone instance of StoryBoard.

The standalone StoryBoard module will install a fully functional, independent
instance of StoryBoard on your node. It includes a local instance of mysql,
an HTTPS vhost using the apache snakeoil certificates, and an automatic
redirect from http://$hostname to https://$hostname/.

    node default {
        class { 'storyboard':
            mysql_database      => 'storyboard',
            mysql_user          => 'storyboard',
            mysql_user_password => 'changeme',
            hostname            => ::fqdn,
            openid_url          => 'https://login.launchpad.net/+openid',
            ssl_cert_file       => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
            ssl_cert_content    => undef,
            ssl_key_file        => '/etc/ssl/private/ssl-cert-snakeoil.key',
            ssl_key_content     => undef,
            ssl_ca_file         => undef,
            ssl_ca_content      => undef
        }
    }

NOTE: If you don't want an SSL host, set all of the ssl_* parameters to
undef.

## ::storyboard::mysql
A module that installs a local mysql database for StoryBoard

This module installs a standalone mysql instance with a StoryBoard database
and a user that is able to access. It is used by the
<code>::storyboard</code> to provide the database, and may be used for minor
customizations of a standalone-like install.

    node default {
    	class { 'storyboard::mysql':
          mysql_database      => 'storyboard',
          mysql_user          => 'storyboard',
          mysql_user_password => 'changeme'
    	}
	}

## ::storyboard::cert
A module that installs an ssl certificate chain for StoryBoard

This module can be used if you want to add SSL/TLS support to the apache
instance that is hosting StoryBoard. Simply tell it where it should read
the contents of the various certificates and keys from, and it will move
them into the correct place for StoryBoard.

Note that this module supports both string content certificates or file
references. To pick one over the other, make sure that the undesired method
is set to <code>undef</code>. You can also customize where the certificate
will be saved, however that's not strictly necessary.

    node default {
        class { 'storyboard::cert':
            $ssl_cert_file    = undef,
            $ssl_cert_content = undef,
            $ssl_cert         = '/etc/ssl/certs/storyboard.openstack.org.pem',

            $ssl_key_file     = undef,
            $ssl_key_content  = undef,
            $ssl_key          = '/etc/ssl/private/storyboard.openstack.org.key',

            $ssl_ca_file      = undef,
            $ssl_ca_content   = undef,
            $ssl_ca           = '/etc/ssl/certs/ca.pem'
        }
    }

## ::storyboard::application
A module that installs the storyboard webclient and API.

This module can be used if you want to provide your own database, and only
want the API, webclient, and storyboard configuration managed on your node.
It will automatically detect the existence of <code>storyboard::cert</code>, 
and adjust the apache vhost accordingly.

    node default {
        class { 'storyboard::application':
            # Installation parameters
            www_root            => '/var/lib/storyboard/www',
            server_admin        => undef,
            hostname            => ::fqdn,
          
            # storyboard.conf parameters
            access_token_ttl    => 3600,
            refresh_token_ttl   => 604800,
            openid_url          => 'https://login.launchpad.net/+openid',
            mysql_host          => 'localhost',
            mysql_port          => 3306,
            mysql_database      => 'storyboard',
            mysql_user          => 'storyboard',
            mysql_user_password => 'changeme'
        }
    }

## ::storyboard::load_projects
A module that seeds the database with a predefined list of projects.

This module will maintain the list of projects in the storyboard database,
and keep it up to date with the content of the provided configuration file.
Projects not found in the file will be deleted, projects not found in the
database will be added. Note that the 'use-storyboard' flag MUST be set.

    node default {
        class { 'storyboard::load_projects':
            source => 'puppet:///modules/openstack_project/projects.yaml'
        }
    }

File content format:

    - project: openstack/storyboard
      description: The StoryBoard API
      use-storyboard: true
    - project: openstack/storyboard-webclient
      description: The StoryBoard HTTP client
      use-storyboard: true

## ::storyboard::load_superusers
A module that maintains the list of superusers.

This module will maintain the list of superusers (administrators) in the
storyboard database, and keep it up to date with the content of the provided
configuration file. Users are referenced by openID and keyed by email
address, however all other information will be persisted from the
OpenID provider.

    node default {
        class { 'storyboard::load_superusers':
            source => 'puppet:///modules/openstack_project/superusers.yaml'
        }
    }

File content format:

    - openid: https://login.launchpad.net/+id/some_openid
      email: your_email@some_email_host.com
    - openid: https://login.launchpad.net/+id/some_other_id
      email: admin_email@some_email_host.com