require 'spec_helper'

describe 'puppetdb::server::jetty_ini', :type => :class do
  context 'on a supported platform' do
    let(:facts) do
      {
        :osfamily                 => 'RedHat',
        :fqdn                     => 'test.domain.local',
      }
    end

    it { should contain_class('puppetdb::server::jetty_ini') }

    describe 'when using default values' do
      it { should contain_ini_setting('puppetdb_host').
        with(
             'ensure'  => 'present',
             'path'    => '/etc/puppetdb/conf.d/jetty.ini',
             'section' => 'jetty',
             'setting' => 'host',
             'value'   => 'localhost'
             )}
      it { should contain_ini_setting('puppetdb_port').
        with(
             'ensure'  => 'present',
             'path'    => '/etc/puppetdb/conf.d/jetty.ini',
             'section' => 'jetty',
             'setting' => 'port',
             'value'   => 8080
             )}
      it { should contain_ini_setting('puppetdb_sslhost').
        with(
             'ensure'  => 'present',
             'path'    => '/etc/puppetdb/conf.d/jetty.ini',
             'section' => 'jetty',
             'setting' => 'ssl-host',
             'value'   => 'test.domain.local'
             )}
      it { should contain_ini_setting('puppetdb_sslport').
        with(
             'ensure'  => 'present',
             'path'    => '/etc/puppetdb/conf.d/jetty.ini',
             'section' => 'jetty',
             'setting' => 'ssl-port',
             'value'   => 8081
             )}
    end

    describe 'when disabling ssl' do
      let(:params) do
        {
          'disable_ssl' => true
        }
      end
      it { should contain_ini_setting('puppetdb_host').
        with(
             'ensure'  => 'present',
             'path'    => '/etc/puppetdb/conf.d/jetty.ini',
             'section' => 'jetty',
             'setting' => 'host',
             'value'   => 'localhost'
             )}
      it { should contain_ini_setting('puppetdb_port').
        with(
             'ensure'  => 'present',
             'path'    => '/etc/puppetdb/conf.d/jetty.ini',
             'section' => 'jetty',
             'setting' => 'port',
             'value'   => 8080
             )}
      it { should contain_ini_setting('puppetdb_sslhost').
        with(
             'ensure'  => 'absent',
             'path'    => '/etc/puppetdb/conf.d/jetty.ini',
             'section' => 'jetty',
             'setting' => 'ssl-host'
             )}
      it { should contain_ini_setting('puppetdb_sslport').
        with(
             'ensure'  => 'absent',
             'path'    => '/etc/puppetdb/conf.d/jetty.ini',
             'section' => 'jetty',
             'setting' => 'ssl-port'
             )}
    end
  end
end
