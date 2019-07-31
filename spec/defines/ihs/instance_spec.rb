require 'spec_helper'
require 'shared_contexts'

describe 'websphere_application_server::ihs::instance' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  # include_context :hiera

  let(:title) { 'HTTPServer' }

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
      target: '/opt/IBM/HTTPServer',
      package: 'com.ibm.websphere.IHSILAN.v85',
      version: '8.5.5000.20130514_1044',
      repository: '/mnt/myorg/ihs/repository.config',
      install_options: '-properties user.ihs.httpPort=80',
      user: 'webadmin',
      group: 'webadmins',
      manage_user: true,
      manage_group: true,
      log_dir: '/opt/log/websphere/httpserver/logs',
      admin_username: 'httpadmin',
      admin_password: 'password',
      webroot: '/opt/web',
      # response_file: nil,
      # imcl_path: nil,
      user_home: '/home/ihs',
      # webroot: "/opt/web",
      # admin_listen_port: "8008",
      # adminconf_template: "websphere/ihs/admin.conf.erb",
      # replace_config: true,
      # server_name: "$::fqdn",
      # manage_htpasswd: true,

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

      it do
        is_expected.to contain_user('webadmin').with(
          ensure: 'present',
          home: '/home/ihs',
          gid: 'webadmins',
        )
      end

      it do
        is_expected.to contain_group('webadmins').with(
          ensure: 'present',
        )
      end

      it do
        is_expected.to contain_ibm_pkg('IHS HTTPServer').with(
          ensure: 'present',
          package: 'com.ibm.websphere.IHSILAN.v85',
          version: '8.5.5000.20130514_1044',
          target: '/opt/IBM/HTTPServer',
          response: nil,
          options: '-properties user.ihs.httpPort=80',
          repository: '/mnt/myorg/ihs/repository.config',
          manage_ownership: true,
          imcl_path: nil,
          package_owner: 'webadmin',
          package_group: 'webadmins',
        )
      end

      it do
        is_expected.to contain_file('/opt/web').with(
          ensure: 'directory',
          require: 'Ibm_pkg[IHS HTTPServer]',
        )
      end

      it do
        is_expected.to contain_file('/opt/log/websphere/httpserver/logs').with(
          ensure: 'directory',
          require: 'Ibm_pkg[IHS HTTPServer]',
        )
      end

      it do
        is_expected.to contain_file('ihs_adminconf_HTTPServer').with(
          ensure: 'file',
          path: '/opt/IBM/HTTPServer/conf/admin.conf',
          mode: '0775',
          replace: true,
          require: 'Ibm_pkg[IHS HTTPServer]',
        )
      end

      it do
        is_expected.to contain_exec('htpasswd for admin HTTPServer').with(
          command: '/opt/IBM/HTTPServer/bin/htpasswd -b -c /opt/IBM/HTTPServer/conf/admin.passwd httpadmin password',
          path: '/bin:/usr/bin:/sbin:/usr/sbin',
          user: 'webadmin',
          require: 'Ibm_pkg[IHS HTTPServer]',
        )
      end

      it do
        is_expected.to contain_service('ihs_admin_HTTPServer').with(
          ensure: 'running',
          start: "su - webadmin -c '/opt/IBM/HTTPServer/bin/adminctl start'",
          stop: "su - webadmin -c '/opt/IBM/HTTPServer/bin/adminctl stop'",
          restart: "su - webadmin -c '/opt/IBM/HTTPServer/bin/adminctl restart'",
          pattern: '/opt/IBM/HTTPServer/bin/httpd -f /opt/IBM/HTTPServer/conf/admin.conf',
          hasstatus: false,
          provider: 'base',
          subscribe: 'File[ihs_adminconf_HTTPServer]',
        )
      end
    end
  end
end
