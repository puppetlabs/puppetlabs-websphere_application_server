require 'spec_helper'
require 'shared_contexts'

describe 'websphere_application_server::profile::dmgr' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  # include_context :hiera

  let(:title) { 'PROFILE_DMGR_01' }

  # below is the facts hash that gives you the ability to mock
  # facts on a per describe/context block.  If you use a fact in your
  # manifest you should mock the facts below.
  let(:extra_facts) do
    {
      'websphere_PROFILE_DMGR_01_CELL_01_dmgrnode01_soap' => '8999',
    }
  end

  # below is a list of the resource parameters that you can override.
  # By default all non-required parameters are commented out,
  # while all required parameters will require you to add a value
  let(:params) do
    {
      instance_base: '/opt/IBM/WebSphere/AppServer',
      cell: 'CELL_01',
      node_name: 'dmgrNode01',
      profile_base: '/opt/IBM/WebSphere/AppServer/profiles',
      # profile_name: "PROFILE_DMGR_01",
      # user: "websphere",
      # group: "websphere",
      # dmgr_host: "$::fqdn",
      # template_path: "undef/profileTemplates/dmgr",
      # options: :undef,
      # manage_service: true,
      manage_sdk: true,
      sdk_name: '9.3',
      # collect_nodes: true,
      # collect_web_servers: true,
      # collect_jvm_logs: true,
      wsadmin_user: 'websphere',
      wsadmin_pass: 'websphere',

    }
  end

  let(:pre_condition) do
    'include websphere_application_server'
  end

  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  on_supported_os(test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts.merge(extra_facts) }

      it { is_expected.to compile }

      it do
        is_expected.to contain_exec('was_profile_dmgr_PROFILE_DMGR_01').with(
          command: '/opt/IBM/WebSphere/AppServer/bin/manageprofiles.sh -create -profileName PROFILE_DMGR_01 -profilePath /opt/IBM/WebSphere/AppServer/profiles/PROFILE_DMGR_01 -templatePath /opt/IBM/WebSphere/AppServer/profileTemplates/dmgr -nodeName dmgrNode01 -hostName foo.example.com -cellName CELL_01 && test -d /opt/IBM/WebSphere/AppServer/profiles/PROFILE_DMGR_01',
          creates: '/opt/IBM/WebSphere/AppServer/profiles/PROFILE_DMGR_01',
          path: '/bin:/usr/bin:/sbin:/usr/sbin',
          cwd: '/opt/IBM/WebSphere/AppServer/bin',
          user: 'websphere',
          timeout: '900',
          returns: ['0', '2'],
        )
      end

      it do
        is_expected.to contain_websphere_application_server__ownership('PROFILE_DMGR_01').with(
          user: 'websphere',
          group: 'websphere',
          path: '/opt/IBM/WebSphere/AppServer/profiles/PROFILE_DMGR_01',
          require: 'Exec[was_profile_dmgr_PROFILE_DMGR_01]',
        )
      end

      it do
        is_expected.to contain_websphere_sdk('PROFILE_DMGR_01_9.3').with(
          profile: 'PROFILE_DMGR_01',
          server: 'all',
          sdkname: '9.3',
          instance_base: '/opt/IBM/WebSphere/AppServer',
          new_profile_default: '9.3',
          command_default: '9.3',
          user: 'websphere',
          username: 'websphere',
          password: 'websphere',
          require: 'Exec[was_profile_dmgr_PROFILE_DMGR_01]',
          subscribe: 'Websphere_application_server::Ownership[PROFILE_DMGR_01]',
        )
      end

      it do
        is_expected.to contain_websphere_application_server__profile__service('PROFILE_DMGR_01').with(
          type: 'dmgr',
          profile_base: '/opt/IBM/WebSphere/AppServer/profiles',
          user: 'websphere',
          wsadmin_user: 'websphere',
          wsadmin_pass: 'websphere',
          require: 'Exec[was_profile_dmgr_PROFILE_DMGR_01]',
          subscribe: 'Websphere_application_server::Ownership[PROFILE_DMGR_01]',
        )
      end
    end
  end
end
