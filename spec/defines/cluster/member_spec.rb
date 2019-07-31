require 'spec_helper'
require 'shared_contexts'

describe 'websphere_application_server::cluster::member' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  # include_context :hiera

  let(:title) { 'AppServer01' }

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
      cluster: 'cluster_01',
      node_name: 'appNode01',
      dmgr_profile: 'PROFILE_DMGR_01',
      profile_base: '/opt/IBM/WebSphere/AppServer/profiles',
      cell: 'CELL_01',
      # cluster_member_name: "AppServer01",
      # ensure: "present",
      # user: "websphere",
      # runas_user: "websphere",
      # runas_group: "websphere",
      # client_inactivity_timeout: nil,
      # gen_unique_ports: nil,
      # jvm_maximum_heap_size: nil,
      # jvm_verbose_mode_class: nil,
      # jvm_verbose_garbage_collection: nil,
      # jvm_verbose_mode_jni: nil,
      # jvm_initial_heap_size: nil,
      # jvm_run_hprof: nil,
      # jvm_hprof_arguments: nil,
      # jvm_debug_mode: nil,
      # jvm_debug_args: nil,
      # jvm_executable_jar_filename: nil,
      # jvm_generic_jvm_arguments: nil,
      # jvm_disable_jit: nil,
      # replicator_entry: nil,
      # total_transaction_timeout: nil,
      # threadpool_webcontainer_min_size: nil,
      # threadpool_webcontainer_max_size: nil,
      # umask: nil,
      wsadmin_user: 'websphere',
      wsadmin_pass: 'password',
      # weight: nil,
      # manage_service: true,
      # dmgr_host: nil,

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
        is_expected.to contain_websphere_cluster_member('AppServer01').with(
          ensure: 'present',
          user: 'websphere',
          dmgr_profile: 'PROFILE_DMGR_01',
          profile: 'AppServer01',
          profile_base: '/opt/IBM/WebSphere/AppServer/profiles',
          cluster: 'cluster_01',
          node_name: 'appNode01',
          cell: 'CELL_01',
          runas_user: 'websphere',
          runas_group: 'websphere',
          client_inactivity_timeout: nil,
          gen_unique_ports: nil,
          jvm_maximum_heap_size: nil,
          jvm_verbose_mode_class: nil,
          jvm_verbose_garbage_collection: nil,
          jvm_verbose_mode_jni: nil,
          jvm_initial_heap_size: nil,
          jvm_run_hprof: nil,
          jvm_hprof_arguments: nil,
          jvm_debug_mode: nil,
          jvm_debug_args: nil,
          jvm_executable_jar_filename: nil,
          jvm_generic_jvm_arguments: nil,
          jvm_disable_jit: nil,
          replicator_entry: nil,
          total_transaction_timeout: nil,
          threadpool_webcontainer_min_size: nil,
          threadpool_webcontainer_max_size: nil,
          umask: nil,
          wsadmin_user: 'websphere',
          wsadmin_pass: 'password',
          weight: nil,
          dmgr_host: nil,
        )
      end

      it do
        is_expected.to contain_websphere_cluster_member_service('AppServer01').with(
          ensure: 'running',
          dmgr_profile: 'PROFILE_DMGR_01',
          profile: 'AppServer01',
          profile_base: '/opt/IBM/WebSphere/AppServer/profiles',
          cell: 'CELL_01',
          node_name: 'appNode01',
          wsadmin_user: 'websphere',
          wsadmin_pass: 'password',
          dmgr_host: nil,
          subscribe: 'Websphere_cluster_member[AppServer01]',
        )
      end
    end
  end
end
