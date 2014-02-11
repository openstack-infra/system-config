Puppet::Type.newtype(:puppetdb_conn_validator) do

  @doc = "Verify that a connection can be successfully established between a node
          and the puppetdb server.  Its primary use is as a precondition to
          prevent configuration changes from being applied if the puppetdb
          server cannot be reached, but it could potentially be used for other
          purposes such as monitoring."

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name, :namevar => true) do
    desc 'An arbitrary name used as the identity of the resource.'
  end

  newparam(:puppetdb_server) do
    desc 'The DNS name or IP address of the server where puppetdb should be running.'
  end

  newparam(:puppetdb_port) do
    desc 'The port that the puppetdb server should be listening on.'
  end

  newparam(:use_ssl) do
    desc 'Whether the connection will be attemped using https'
    defaultto true
  end

  newparam(:timeout) do
    desc 'The max number of seconds that the validator should wait before giving up and deciding that puppetdb is not running; defaults to 15 seconds.'
    defaultto 15

    validate do |value|
      # This will raise an error if the string is not convertible to an integer
      Integer(value)
    end

    munge do |value|
      Integer(value)
    end
  end

end
