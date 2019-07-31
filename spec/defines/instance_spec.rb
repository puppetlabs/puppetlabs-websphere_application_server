require 'spec_helper'
require 'shared_contexts'

describe 'websphere_application_server::instance' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  # include_context :hiera

  let(:title) { 'WAS9' }

  # below is the facts hash that gives you the ability to mock
  # facts on a per describe/context block.  If you use a fact in your
  # manifest you should mock the facts below.
  let(:extra_facts) do
    {}
  end

  # below is a list of the resource parameters that you can override.
  # By default all non-required parameters are commented out,
  # while all required parameters will require you to add a value
  let(:params) do
    {
      # base_dir: :undef,
      # package: :undef,
      # response_file: :undef,
      # install_options: :undef,
      # jdk_package_name: 'jdk',
      # jdk_package_version: '9.0',
      # imcl_path: :undef,
      # profile_base: "/$title/AppServer/profiles",
      manage_user: true,
      manage_group: true,
      user: 'websphere',
      group: 'websphere',
      target: '/opt/IBM/WebSphere/AppServer',
      repository: '/mnt/myorg/was/repository.config',
      package: 'com.ibm.websphere.ND.v90',
      version: '9.0.0.20160526_1854',
      # user_home: "/$title/AppServer",

    }
  end

  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  on_supported_os(test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts.merge(extra_facts) }

      describe 'without jdk specified' do
        it { is_expected.to raise_error Puppet::PreformattedError, %r{When installing WebSphere AppServer 9, you must specify a JDK} }
      end

      context 'installing websphere 9' do
        describe 'happy path' do
          let(:params) do
            super().merge(
              jdk_package_name: 'com.ibm.websphere.IBMJAVA.v71',
              jdk_package_version: '7.1.2000.20141116_0823',
            )
          end

          it { is_expected.to compile }
          it do
            is_expected.to contain_user('websphere').with(
              ensure: 'present',
              home: '/opt/IBM/WebSphere/AppServer',
              gid: 'websphere',
            )
          end

          it do
            is_expected.to contain_group('websphere').with(
              ensure: 'present',
            )
          end

          it do
            is_expected.to contain_ibm_pkg('WAS9').with(
              ensure: 'present',
              package: 'com.ibm.websphere.ND.v90',
              version: '9.0.0.20160526_1854',
              target: '/opt/IBM/WebSphere/AppServer',
              response: nil,
              options: nil,
              repository: '/mnt/myorg/was/repository.config',
              imcl_path: nil,
              manage_ownership: true,
              package_owner: 'websphere',
              package_group: 'websphere',
              jdk_package_name: 'com.ibm.websphere.IBMJAVA.v71',
              jdk_package_version: '7.1.2000.20141116_0823',
              user: 'websphere',
            )
          end

          it do
            is_expected.to contain_file('/opt/IBM/WebSphere/AppServer/profiles').with(
              ensure: 'directory',
              owner: 'websphere',
              group: 'websphere',
              require: 'Ibm_pkg[WAS9]',
            )
          end

          it do
            is_expected.to contain_concat__fragment('WAS9_facts').with(
              target: '/etc/puppetlabs/facter/facts.d/websphere.yaml',
              content: "## Instance: WAS9\nwas9_name: WAS9\nwas9_target: /opt/IBM/WebSphere/AppServer\nwas9_user: websphere\nwas9_group: websphere\nwas9_profile_base: /opt/IBM/WebSphere/AppServer/profiles\n",
              require: 'Ibm_pkg[WAS9]',
            )
          end
        end
      end
    end
  end
end
