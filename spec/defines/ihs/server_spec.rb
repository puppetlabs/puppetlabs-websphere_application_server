require 'spec_helper'
require 'shared_contexts'

describe 'websphere_application_server::ihs::server' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  # include_context :hiera

  let(:title) { 'test' }

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
      target: '/opt/IBM/HTTPServer',
      log_dir: '/opt/IBM/HTTPServer/logs',
      plugin_base: '/opt/IBM/Plugins',
      cell: 'CELL_01',
      access_log: '/opt/IBM/HTTPServer/logs/access_log',
      error_log: '/opt/IBM/HTTPServer/logs/error_log',
      listen_port: 10_080,
      status: 'stopped',
      # httpd_config: "undef/conf/httpd_test.conf",
      user: 'webadmin',
      group: 'webadmins',
      # docroot: "undef/htdocs",
      # instance: "test",
      # httpd_config_template: "$module_name/ihs/httpd.conf.erb",
      # timeout: "300",
      # max_keep_alive_requests: "100",
      # keep_alive: "On",
      # keep_alive_timeout: "10",
      # thread_limit: "25",
      # server_limit: "64",
      # start_servers: "1",
      # max_clients: "600",
      # min_spare_threads: "25",
      # max_spare_threads: "75",
      # threads_per_child: "25",
      # max_requests_per_child: "25",
      # limit_request_field_size: "12392",
      # listen_address: "$::fqdn",
      # server_admin_email: "user@example.com",
      # server_name: "$::fqdn",
      server_listen_port: 80,
      # pid_file: "test.pid",
      # replace_config: true,
      # directory_index: "index.html index.html.var",
      # log_dir: "undef/logs",
      # access_log: "access_log",
      # error_log: "error_log",
      # export_node: true,
      # export_server: true,
      # node_name: "$::fqdn",
      # node_hostname: "$::fqdn",
      # node_os: :undef,
      # cell: :undef,
      admin_username: 'httpadmin',
      admin_password: 'password',
      # propagate_keyring: true,
      dmgr_host: 'appserver01.foo.com',

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
        is_expected.to contain_file('test /opt/IBM/HTTPServer/htdocs').with(
          ensure: 'directory',
          path: '/opt/IBM/HTTPServer/htdocs',
        )
      end

      it do
        is_expected.to contain_file('/opt/IBM/Plugins/config/test').with(
          ensure: 'directory',
        )
      end

      it do
        is_expected.to contain_exec('test_log_dir').with(
          command: 'mkdir -p /opt/IBM/HTTPServer/logs',
          creates: '/opt/IBM/HTTPServer/logs',
        )
      end

      it do
        is_expected.to contain_file_line('Adding user').with(
          path: '/opt/IBM/HTTPServer/conf/httpd_test.conf',
          line: 'User webadmin',
          match: '^User $',
        )
      end

      it do
        is_expected.to contain_file_line('Adding group').with(
          path: '/opt/IBM/HTTPServer/conf/httpd_test.conf',
          line: 'Group webadmins',
          match: '^Group $',
        )
      end

      it do
        is_expected.to contain_file('/etc/ld.so.conf.d/httpd-pp-lib.conf').with(
          ensure: 'present',
        )
      end

      it do
        is_expected.to contain_file_line('Adding shared library paths').with(
          ensure: 'present',
          path: '/etc/ld.so.conf.d/httpd-pp-lib.conf',
          line: '/opt/IBM/HTTPServer/lib',
        )
      end

      it do
        is_expected.to contain_exec('refresh_ld_cache').with(
          command: 'ldconfig',
          path: ['/sbin/'],
          refreshonly: true,
          subscribe: 'File_line[Adding shared library paths]',
        )
      end

      it do
        is_expected.to contain_file('test_httpd_config').with(
          ensure: 'file',
          path: '/opt/IBM/HTTPServer/conf/httpd_test.conf',
          replace: true,
        )
      end

      it do
        is_expected.to contain_service('test_httpd_config').with(
          ensure: 'stopped',
          start: 'su - webadmin -c "/opt/IBM/HTTPServer/bin/adminctl start"',
          stop: 'su - webadmin -c "/opt/IBM/HTTPServer/bin/adminctl stop"',
          restart: 'su - webadmin -c "/opt/IBM/HTTPServer/bin/adminctl restart"',
          hasstatus: false,
          pattern: '/opt/IBM/HTTPServer/bin/httpd.*-f /opt/IBM/HTTPServer/conf/admin.conf',
          provider: 'base',
        )
      end

      it do
        is_expected.to contain_service('test_httpd').with(
          ensure: 'running',
          start: "su - webadmin -c \"/opt/IBM/HTTPServer/bin/apachectl -k start -f '/opt/IBM/HTTPServer/conf/httpd_test.conf'\"",
          stop: "su - webadmin -c \"/opt/IBM/HTTPServer/bin/apachectl -k stop -f '/opt/IBM/HTTPServer/conf/httpd_test.conf'\"",
          restart: "su - webadmin -c \"/opt/IBM/HTTPServer/bin/apachectl -k restart -f '/opt/IBM/HTTPServer/conf/httpd_test.conf'\"",
          hasstatus: false,
          pattern: '/opt/IBM/HTTPServer/bin/httpd.*-f /opt/IBM/HTTPServer/conf/httpd_test.conf',
          provider: 'base',
          subscribe: 'File[test_httpd_config]',
        )
      end

      # it do
      #   is_expected.to contain_websphere_node('ihs_test_$::fqdn').with(
      #     ensure: 'present',
      #     node_name: '$::fqdn',
      #     os: :undef,
      #     hostname: '$::fqdn',
      #     cell: :undef,
      #     dmgr_host: :undef,
      #   )
      # end

      # it do
      #   is_expected.to contain_websphere_web_server('web_test_appserver01.foo.com').with(
      #     ensure: 'present',
      #     name: 'test',
      #     node_name: '$::fqdn',
      #     cell: :undef,
      #     admin_user: 'httpadmin',
      #     admin_pass: 'password',
      #     plugin_base: '/opt/IBM/Plugins',
      #     install_root: :undef,
      #     config_file: 'undef/conf/httpd_test.conf',
      #     access_log: 'access_log',
      #     error_log: 'error_log',
      #     web_port: '10080',
      #     propagate_keyring: true,
      #     dmgr_host: :undef,
      #     require: 'Websphere_node[ihs_test_$::fqdn]',
      #   )
      # end
    end
  end
end
