require 'spec_helper'
require 'shared_contexts'

describe 'websphere_application_server::profile::service' do
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
    {}
  end

  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  on_supported_os(test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts.merge(extra_facts) }
      let(:params) do
        {
          type: 'appserver',
          profile_base: '/opt/IBM/WebSphere/AppServer/profiles',
          # profile_name: "$title",
          # user: "root",
          # ensure: "running",
          start: 'start command',
          stop: 'stop command',
          status: 'status command',
          restart: 'restart command',
          # wsadmin_user: :undef,
          # wsadmin_pass: :undef,
        }
      end

      it { is_expected.to compile }
      context 'supplied commands' do
        it do
          is_expected.to contain_service('was_profile_PROFILE_DMGR_01').with(
            ensure: 'running',
            start: 'start command',
            stop: 'stop command',
            status: 'status command',
            restart: 'restart command',
            provider: 'base',
          )
        end
      end

      context 'default comnands' do
        it do
          is_expected.to contain_service('was_profile_PROFILE_DMGR_01').with(
            ensure: 'running',
            start: 'start command',
            stop: 'stop command',
            status: 'status command',
            restart: 'restart command',
            provider: 'base',
          )
        end
      end
    end
  end
end
