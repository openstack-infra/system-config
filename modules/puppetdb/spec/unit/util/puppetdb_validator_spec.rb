require 'spec_helper'
require 'puppet/util/puppetdb_validator'

describe 'Puppet::Util::PuppetdbValidator' do

  before do
    response_ok = stub()
    response_ok.stubs(:kind_of?).with(Net::HTTPSuccess).returns(true)
    response_not_found = stub()
    response_not_found.stubs(:kind_of?).with(Net::HTTPSuccess).returns(false)
    response_not_found.stubs(:code).returns(404)
    response_not_found.stubs(:msg).returns('Not found')

    conn_ok = stub()
    conn_ok.stubs(:get).with('/metrics/mbean/java.lang:type=Memory', {"Accept" => "application/json"}).returns(response_ok)
    conn_ok.stubs(:read_timeout=).with(2)
    conn_ok.stubs(:open_timeout=).with(2)

    conn_not_found = stub()
    conn_not_found.stubs(:get).with('/metrics/mbean/java.lang:type=Memory', {"Accept" => "application/json"}).returns(response_not_found)

    Puppet::Network::HttpPool.stubs(:http_instance).raises('Unknown host')
    Puppet::Network::HttpPool.stubs(:http_instance).with('mypuppetdb.com', 8080, true).raises('Connection refused')
    Puppet::Network::HttpPool.stubs(:http_instance).with('mypuppetdb.com', 8081, true).returns(conn_ok)
    Puppet::Network::HttpPool.stubs(:http_instance).with('wrongserver.com', 8081, true).returns(conn_not_found)
    Net::HTTP.stubs(:new).with('mypuppetdb.com', 8080).returns(conn_ok)
  end

  it 'returns true if connection succeeds' do
    validator = Puppet::Util::PuppetdbValidator.new('mypuppetdb.com', 8081)
    validator.attempt_connection.should be_true
  end

  it 'should still validate without ssl' do
    Puppet[:configtimeout] = 2
    validator = Puppet::Util::PuppetdbValidator.new('mypuppetdb.com', 8080, false)
    validator.attempt_connection.should be_true
  end

  it 'returns false and issues an appropriate notice if connection is refused' do
    puppetdb_server = 'mypuppetdb.com'
    puppetdb_port = 8080
    validator = Puppet::Util::PuppetdbValidator.new(puppetdb_server, puppetdb_port)
    Puppet.expects(:notice).with("Unable to connect to puppetdb server (#{puppetdb_server}:#{puppetdb_port}): Connection refused")
    #Puppet.expects(:notice).with("Unable to connect to puppetdb server (#{puppetdb_server}:#{puppetdb_port}): [404] Not found")
    validator.attempt_connection.should be_false    
  end

  it 'returns false and issues an appropriate notice if connection succeeds but puppetdb is not available' do
    puppetdb_server = 'wrongserver.com'
    puppetdb_port = 8081
    validator = Puppet::Util::PuppetdbValidator.new(puppetdb_server, puppetdb_port)
    Puppet.expects(:notice).with("Unable to connect to puppetdb server (#{puppetdb_server}:#{puppetdb_port}): [404] Not found")
    validator.attempt_connection.should be_false    
  end


  it 'returns false and issues an appropriate notice if host:port is unreachable or does not exist' do
    puppetdb_server = 'non-existing.com'
    puppetdb_port = nil
    validator = Puppet::Util::PuppetdbValidator.new(puppetdb_server, puppetdb_port)
    Puppet.expects(:notice).with("Unable to connect to puppetdb server (#{puppetdb_server}:#{puppetdb_port}): Unknown host")
    validator.attempt_connection.should be_false    
  end


end
