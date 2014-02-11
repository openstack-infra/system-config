require 'spec_helper_acceptance'

describe 'ini_subsetting resource' do
  after :all do
    shell("rm /tmp/*.ini", :acceptable_exit_codes => [0,1])
  end

  shared_examples 'has_content' do |path,pp,content|
    before :all do
      shell("rm #{path}", :acceptable_exit_codes => [0,1])
    end
    after :all do
      shell("cat #{path}", :acceptable_exit_codes => [0,1])
      shell("rm #{path}", :acceptable_exit_codes => [0,1])
    end

    it 'applies the manifest twice with no stderr' do
      expect(apply_manifest(pp, :catch_failures => true).stderr).to eq("")
      expect(apply_manifest(pp, :catch_changes => true).stderr).to eq("")
    end

    describe file(path) do
      it { should be_file }
      it { should contain(content) }
    end
  end

  shared_examples 'has_error' do |path,pp,error|
    before :all do
      shell("rm #{path}", :acceptable_exit_codes => [0,1])
    end
    after :all do
      shell("cat #{path}", :acceptable_exit_codes => [0,1])
      shell("rm #{path}", :acceptable_exit_codes => [0,1])
    end

    it 'applies the manifest and gets a failure message' do
      expect(apply_manifest(pp, :expect_failures => true).stderr).to match(error)
    end

    describe file(path) do
      it { should_not be_file }
    end
  end

  describe 'ensure, section, setting, subsetting, & value parameters' do
    context '=> present with subsections' do
      pp = <<-EOS
      ini_subsetting { 'ensure => present for alpha':
        ensure     => present,
        path       => '/tmp/ini_subsetting.ini',
        section    => 'one',
        setting    => 'key',
        subsetting => 'alpha',
        value      => 'bet',
      }
      ini_subsetting { 'ensure => present for beta':
        ensure     => present,
        path       => '/tmp/ini_subsetting.ini',
        section    => 'one',
        setting    => 'key',
        subsetting => 'beta',
        value      => 'trons',
      }
      EOS

      it 'applies the manifest twice with no stderr' do
        expect(apply_manifest(pp, :catch_failures => true).stderr).to eq("")
        expect(apply_manifest(pp, :catch_changes => true).stderr).to eq("")
      end

      describe file('/tmp/ini_subsetting.ini') do
        it { should be_file }
        it { should contain("[one]\nkey = alphabet betatrons") }
      end
    end

    context 'ensure => absent' do
      before :all do
        shell('echo -e "[one]\nkey = alphabet betatrons" > /tmp/ini_subsetting.ini')
      end

      pp = <<-EOS
      ini_subsetting { 'ensure => absent for subsetting':
        ensure     => absent,
        path       => '/tmp/ini_subsetting.ini',
        section    => 'one',
        setting    => 'key',
        subsetting => 'alpha',
      }
      EOS

      it 'applies the manifest twice with no stderr' do
        expect(apply_manifest(pp, :catch_failures => true).stderr).to eq("")
        expect(apply_manifest(pp, :catch_changes  => true).stderr).to eq("")
      end

      describe file('/tmp/ini_subsetting.ini') do
        it { should be_file }
        it { should contain('[one]') }
        it { should contain('key = betatrons') }
        it { should_not contain('alphabet') }
      end
    end
  end

  describe 'subsetting_separator' do
    {
      ""                                => "two = twinethree foobar",
      #"subsetting_separator => '',"     => "two = twinethreefoobar", # breaks regex
      "subsetting_separator => ',',"    => "two = twinethree,foobar",
      "subsetting_separator => '   ',"  => "two = twinethree   foobar",
      "subsetting_separator => ' == '," => "two = twinethree == foobar",
      "subsetting_separator => '=',"    => "two = twinethree=foobar",
      #"subsetting_separator => '---',"  => "two = twinethree---foobar", # breaks regex
    }.each do |parameter, content|
      context "with \"#{parameter}\" makes \"#{content}\"" do
        pp = <<-EOS
        ini_subsetting { "with #{parameter} makes #{content}":
          ensure     => present,
          section    => 'one',
          setting    => 'two',
          subsetting => 'twine',
          value      => 'three',
          path       => '/tmp/subsetting_separator.ini',
          #{parameter}
        }
        ini_subsetting { "foobar":
          ensure     => present,
          section    => 'one',
          setting    => 'two',
          subsetting => 'foo',
          value      => 'bar',
          path       => '/tmp/subsetting_separator.ini',
          #{parameter}
        }
        EOS

        it_behaves_like 'has_content', '/tmp/subsetting_separator.ini', pp, content
      end
    end
  end
end
