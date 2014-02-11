# See: #10295 for more details.
#
# This is a workaround for bug: #4248 whereby ruby files outside of the normal
# provider/type path do not load until pluginsync has occured on the puppetmaster
#
# In this case I'm trying the relative path first, then falling back to normal
# mechanisms. This should be fixed in future versions of puppet but it looks
# like we'll need to maintain this for some time perhaps.
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__),"..","..",".."))
require 'puppet/util/puppetdb_validator'

# This file contains a provider for the resource type `puppetdb_conn_validator`,
# which validates the puppetdb connection by attempting an https connection.

Puppet::Type.type(:puppetdb_conn_validator).provide(:puppet_https) do
  desc "A provider for the resource type `puppetdb_conn_validator`,
        which validates the puppetdb connection by attempting an https
        connection to the puppetdb server.  Uses the puppet SSL certificate
        setup from the local puppet environment to authenticate."

  def exists?
    start_time = Time.now
    timeout = resource[:timeout]

    success = validator.attempt_connection

    while success == false && ((Time.now - start_time) < timeout)
      # It can take several seconds for the puppetdb server to start up;
      # especially on the first install.  Therefore, our first connection attempt
      # may fail.  Here we have somewhat arbitrarily chosen to retry every 2
      # seconds until the configurable timeout has expired.
      Puppet.notice("Failed to connect to puppetdb; sleeping 2 seconds before retry")
      sleep 2
      success = validator.attempt_connection
    end

    unless success
      Puppet.notice("Failed to connect to puppetdb within timeout window of #{timeout} seconds; giving up.")
    end

    success
  end

  def create
    # If `#create` is called, that means that `#exists?` returned false, which
    # means that the connection could not be established... so we need to
    # cause a failure here.
    raise Puppet::Error, "Unable to connect to puppetdb server! (#{@validator.puppetdb_server}:#{@validator.puppetdb_port})"
  end

  # @api private
  def validator
    @validator ||= Puppet::Util::PuppetdbValidator.new(resource[:puppetdb_server], resource[:puppetdb_port], resource[:use_ssl])
  end

end

