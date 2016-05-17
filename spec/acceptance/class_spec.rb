require 'spec_helper_acceptance'
require_relative './websphere_helper.rb'

describe 'websphere_application_server class:' do
  context 'default parameters' do
    it 'should run successfully' do
      pp = <<-EOS
      class { 'websphere_application_server': }
      EOS

      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

    describe file($default_base_dir) do
      it { is_expected.to be_directory}
      it { is_expected.to be_owned_by $default_user }
      it { is_expected.to be_grouped_into $default_group }
    end
  end

  context 'should set user and group:' do
    it 'should run successfully' do
      pp = <<-EOS
      class { 'websphere_application_server':
        user  => 'webadmin',
        group => 'webadmins',
      }
      EOS

      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

    describe file($default_base_dir) do
      it { is_expected.to be_directory}
      it { is_expected.to be_owned_by 'webadmin' }
      it { is_expected.to be_grouped_into 'webadmins' }
    end
  end

  context 'should be installed at base_dir:' do
    it 'should run successfully' do
      pp = <<-EOS
      file { '/opt/myIBM':
        ensure => directory,
      }
      class { 'websphere_application_server':
        base_dir => '/opt/myIBM',
        require  => File['/opt/myIBM'],
      }
      EOS

      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

    describe file('/etc/puppetlabs/facter/facts.d/websphere.yaml') do
      it { is_expected.to be_file }
      it { is_expected.to contain %r{websphere_base_dir: /opt/myIBM} }
    end
  end
end
