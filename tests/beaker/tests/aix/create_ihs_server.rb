require 'erb'
require 'master_manipulator'
require 'websphere_helper'
require 'installer_constants'

test_name 'FM-5225 - C93850 - Create IHS server'

# Teardown
teardown do
  confine_block(:except, :roles => %w{master dashboard database}) do
    agents.each do |agent|
      #comment out due to FM-5130
      #remove_websphere_instance('websphere_application_server', '/opt/log/websphere /opt/IBM')
    end
  end
end

#Get the ERB manifest:
base_dir                = WebSphereConstants.base_dir
instance_base           = WebSphereConstants.instance_base
profile_base            = WebSphereConstants.profile_base
was_installer           = WebSphereConstants.was_installer
package_name            = WebSphereConstants.package_name
package_ihs             = WebSphereConstants.package_ihs
package_version         = WebSphereConstants.package_version
package_plugin          = WebSphereConstants.package_plugin
instance_name           = WebSphereConstants.instance_name
cell                    = WebSphereConstants.cell
user                    = WebSphereConstants.user
group                   = WebSphereConstants.group
ihs_target              = WebSphereConstants.ihs_target

local_files_root_path = ENV['FILES'] || "tests/beaker/files"
manifest_template     = File.join(local_files_root_path, 'websphere_instance_manifest.erb')
manifest_erb          = ERB.new(File.read(manifest_template)).result(binding)

# create appserver profile manifest:
pp = <<-MANIFEST
websphere_application_server::ihs::instance { '#{ihs_target}':
  target           => "#{base_dir}/#{ihs_target}",
  package          => "#{package_ihs}",
  version          => "#{package_version}",
  repository       => '/mnt/QA_resources/ibm_websphere/ihs_ilan/repository.config',
  install_options  => '-properties user.ihs.httpPort=80',
  user             => "#{user}",
  group            => "#{group}",
  manage_user      => false,
  manage_group     => false,
  log_dir          => '/opt/log/websphere/httpserver',
  admin_username   => 'httpadmin',
  admin_password   => 'password',
  webroot          => '/opt/web',
}

ibm_pkg { 'Plugins':
  ensure     => 'present',
  target     => "#{base_dir}/Plugins",
  repository => '/mnt/QA_resources/ibm_websphere/plg_ilan/repository.config',
  package    => "#{package_plugin}",
  version    => "#{package_version}",
  require    => Websphere_application_server::Ihs::Instance['#{ihs_target}'],
}

websphere_application_server::ihs::server { 'ihs_server':
  target      => "#{base_dir}/#{ihs_target}",
  log_dir     => '/opt/log/websphere/httpserver',
  plugin_dir  => "#{base_dir}/Plugins/config/test",
  plugin_base => "#{base_dir}/Plugins",
  cell        => "#{cell}"
  config_file => "#{base_dir}/#{ihs_target}/conf/httpd_test.conf",
  access_log  => '/opt/log/websphere/httpserver/access_log',
  error_log   => '/opt/log/websphere/httpserver/error_log',
  listen_port => '10080',
  require     => Ibm_pkg['Plugins'],
}
MANIFEST

step 'add create profile manifest to manifest_erb file'
manifest_erb << pp
puts manifest_erb

step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, :manifest => manifest_erb)
inject_site_pp(master, get_site_pp_path(master), site_pp)

# config server scoped variable  manifest
confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    step 'Run puppet agent to create profile: appserver:'
    expect_failure('Expected to fail due to FM-5093, FM-5130, and FM-5150') do
      on(agent, puppet('agent -t'), :acceptable_exit_codes => 1) do |result|
        assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
      end
    end

    step "Verify the ihs server is created and working properly"
    # Comment out the below line due to FM-5093, FM-5130, and FM-5150
    #verify_websphere(agent, "#{base_dir}/#{ihs_target}/bin/apachectl restart", "successfully")
  end
end
