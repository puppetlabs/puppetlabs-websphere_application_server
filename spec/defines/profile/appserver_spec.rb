require 'spec_helper'
require 'shared_contexts'

describe 'websphere_application_server::profile::appserver' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  # include_context :hiera

  let(:title) { 'PROFILE_APP_001' }

  # below is the facts hash that gives you the ability to mock
  # facts on a per describe/context block.  If you use a fact in your
  # manifest you should mock the facts below.
  let(:extra_facts) do
    {}
  end

  let(:pre_condition) do
    'include websphere_application_server'
  end

  # below is a list of the resource parameters that you can override.
  # By default all non-required parameters are commented out,
  # while all required parameters will require you to add a value
  let(:params) do
    {
      instance_base: '/opt/IBM/WebSphere/AppServer',
      profile_base: '/opt/IBM/WebSphere/AppServer/profiles',
      cell: 'CELL_01',
      node_name: 'appNode01',
      # profile_name: "PROFILE_APP_001",
      # user: "websphere",
      # group: "websphere",
      dmgr_host: 'dmgr.example.com',
      # dmgr_port: nil,
      template_path: '/opt/IBM/WebSphere/AppServer/profileTemplates/managed',
      # options: nil,
      manage_federation: true,
      manage_service: true,
      manage_sdk: true,
      sdk_name: '1.7.1_64',
      wsadmin_user: 'websphere',
      wsadmin_pass: 'password',

    }
  end

  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  on_supported_os(test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts.merge(extra_facts) }

      it { is_expected.to compile }

      it do
        is_expected.to contain_exec('was_profile_app_PROFILE_APP_001').with(
          command: '/opt/IBM/WebSphere/AppServer/bin/manageprofiles.sh -create -profileName PROFILE_APP_001 -profilePath /opt/IBM/WebSphere/AppServer/profiles/PROFILE_APP_001 -templatePath /opt/IBM/WebSphere/AppServer/profileTemplates/managed -nodeName appNode01 -hostName foo.example.com -federateLater true -cellName standalone && test -d /opt/IBM/WebSphere/AppServer/profiles/PROFILE_APP_001',
          creates: '/opt/IBM/WebSphere/AppServer/profiles/PROFILE_APP_001',
          cwd: '/opt/IBM/WebSphere/AppServer',
          path: '/bin:/usr/bin:/sbin:/usr/sbin',
          user: 'websphere',
          timeout: '900',
          returns: ['0', '2'],
        )
      end

      it do
        is_expected.to contain_websphere_application_server__ownership('PROFILE_APP_001').with(
          user: 'websphere',
          group: 'websphere',
          path: '/opt/IBM/WebSphere/AppServer/profiles/PROFILE_APP_001',
          require: 'Exec[was_profile_app_PROFILE_APP_001]',
        )
      end

      it do
        is_expected.to contain_websphere_federate('PROFILE_APP_001_dmgr.example.com_CELL_01').with(
          ensure: 'present',
          node_name: 'appNode01',
          cell: 'CELL_01',
          profile_base: '/opt/IBM/WebSphere/AppServer/profiles',
          profile: 'PROFILE_APP_001',
          dmgr_host: 'dmgr.example.com',
          user: 'websphere',
          username: 'websphere',
          password: 'password',
          before: 'Websphere_application_server::Profile::Service[PROFILE_APP_001]',
        )
      end

      it do
        is_expected.to contain_websphere_sdk('PROFILE_APP_001_1.7.1_64').with(
          profile_base: '/opt/IBM/WebSphere/AppServer/profiles',
          profile: 'PROFILE_APP_001',
          node_name: 'appNode01',
          server: 'all',
          sdkname: '1.7.1_64',
          instance_base: '/opt/IBM/WebSphere/AppServer',
          new_profile_default: '1.7.1_64',
          command_default: '1.7.1_64',
          user: 'websphere',
          username: 'websphere',
          password: 'password',
          require: 'Websphere_federate[PROFILE_APP_001_dmgr.example.com_CELL_01]',
          notify: 'Websphere_application_server::Profile::Service[PROFILE_APP_001]',
        )
      end

      it do
        is_expected.to contain_websphere_application_server__profile__service('PROFILE_APP_001').with(
          type: 'app',
          profile_base: '/opt/IBM/WebSphere/AppServer/profiles',
          user: 'websphere',
          wsadmin_user: 'websphere',
          wsadmin_pass: 'password',
          require: 'Exec[was_profile_app_PROFILE_APP_001]',
          subscribe: 'Websphere_application_server::Ownership[PROFILE_APP_001]',
        )
      end
    end
  end
end
