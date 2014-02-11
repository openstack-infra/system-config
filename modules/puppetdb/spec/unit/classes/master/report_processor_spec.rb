require 'spec_helper'

describe 'puppetdb::master::report_processor', :type => :class do
  context 'on a supported platform' do
    let(:facts) do
      {
          :osfamily                 => 'RedHat',
          :clientcert               => 'test.domain.local',
      }
    end

    it { should contain_class('puppetdb::master::report_processor') }

    describe 'when using default values' do
      it { should contain_ini_subsetting('puppet.conf/reports/puppetdb').
        with(
        'ensure'                => 'absent',
        'path'                  => '/etc/puppet/puppet.conf',
        'section'               => 'master',
        'setting'               => 'reports',
        'subsetting'            => 'puppetdb',
        'subsetting_separator'  => ','
        )}
    end

    describe 'when enabling reports' do
      let(:params) do
        {
            'enable' => true
        }
      end

      it { should contain_ini_subsetting('puppet.conf/reports/puppetdb').
          with(
          'ensure'                => 'present',
          'path'                  => '/etc/puppet/puppet.conf',
          'section'               => 'master',
          'setting'               => 'reports',
          'subsetting'            => 'puppetdb',
          'subsetting_separator'  => ','
      )}
    end
  end
end
