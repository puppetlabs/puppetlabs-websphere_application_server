require 'spec_helper'
require 'shared_contexts'

describe 'websphere_application_server' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  # include_context :hiera

  # below is the facts hash that gives you the ability to mock
  # facts on a per describe/context block.  If you use a fact in your
  # manifest you should mock the facts below.
  let(:extra_facts) do
    {
      id: 'root',
      concat_basedir: '/dne',
      osfamily: 'Debian',
      path: '/opt/puppetlabs/bin',
    }
  end

  # below is a list of the resource parameters that you can override.
  # By default all non-required parameters are commented out,
  # while all required parameters will require you to add a value
  let(:params) do
    {
      # base_dir: "/opt/IBM",
      # group: "websphere",
      # user: "websphere",
      # user_home: "/opt/IBM",
      # manage_group: true,
      # manage_user: true,
    }
  end

  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)

  on_supported_os(test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts.merge(extra_facts) }

      it { is_expected.to compile }

      context 'with default parameters' do
        it { is_expected.to contain_class('websphere_application_server') }
      end

      it do
        is_expected.to contain_user('websphere').with(
          ensure: 'present',
          home: '/opt/IBM',
          gid: 'websphere',
        )
      end

      it do
        is_expected.to contain_group('websphere').with(
          ensure: 'present',
        )
      end

      java_prefs = [
        '/opt/IBM',
        '/opt/IBM/.java',
        '/opt/IBM/.java/systemPrefs',
        '/opt/IBM/.java/userPrefs',
        '/opt/IBM/workspace',
      ]
      java_prefs.each do |file|
        it do
          is_expected.to contain_file(file).with(
            ensure: 'directory',
            owner: 'websphere',
            group: 'websphere',
          )
        end
      end

      it do
        is_expected.to contain_concat('/etc/puppetlabs/facter/facts.d/websphere.yaml').with(
          ensure: 'present',
        )
      end

      it do
        is_expected.to contain_concat__fragment('websphere_facts_header').with(
          target: '/etc/puppetlabs/facter/facts.d/websphere.yaml',
          order: '01',
          content: "---\nwebsphere_base_dir: /opt/IBM\n",
        )
      end
    end
  end
end
