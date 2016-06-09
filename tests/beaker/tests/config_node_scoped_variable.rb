require 'erb'
require 'master_manipulator'
require 'websphere_helper'
require 'installer_constants'

test_name 'FM-5222 - C93843 - Config node scoped variable'

#getting a fresh VM from vmPooler
node_name = get_fresh_node('centos-6-x86_64')

# Teardown
teardown do
  confine_block(:except, :roles => %w{master dashboard database}) do
    agents.each do |agent|
      #comment out due to FM-5130
      #remove_websphere_instance('websphere_application_server', '/opt/log/websphere /opt/IBM')
    end
    return_node_to_pooler(node_name)
  end
end

#Get the ERB manifest:
base_dir                = WebSphereConstants.base_dir
instance_base           = WebSphereConstants.instance_base
profile_base            = WebSphereConstants.profile_base
was_installer           = WebSphereConstants.was_installer
package_name            = WebSphereConstants.package_name
package_version         = WebSphereConstants.package_version
update_package_version  = WebSphereConstants.update_package_version
instance_name           = WebSphereConstants.instance_name
fixpack_installer       = WebSphereConstants.fixpack_installer
java_installer          = WebSphereConstants.java_installer
java_package            = WebSphereConstants.java_package
java_version            = WebSphereConstants.java_version
cell                    = WebSphereConstants.cell
appserver_title         = WebSphereConstants.appserver_title
user                    = WebSphereConstants.user

local_files_root_path = ENV['FILES'] || "tests/beaker/files"
manifest_template     = File.join(local_files_root_path, 'websphere_fixpack_manifest.erb')
manifest_erb          = ERB.new(File.read(manifest_template)).result(binding)

# create appserver profile manifest:
pp = <<-MANIFEST
->
websphere_application_server::profile::appserver { '#{appserver_title}':
  instance_base  => "#{instance_base}",
  profile_base   => "#{profile_base}",
  cell           => "#{cell}",
  node_name      => "#{node_name}",
}

websphere_variable { "#{cell}:node:#{node_name}":
  ensure       => 'present',
  variable     => 'NODE_LOG_ROOT',
  value        => "/var/log/websphere/wasmgmtlogs/#{node_name}",
  scope        => 'node',
  node         => "#{node_name}",
  cell         => "#{cell}",
  dmgr_profile => "#{appserver_title}",
  profile_base => "#{profile_base}",
  user         => "#{user}",
  require      => Websphere_application_server::Profile::Appserver['#{appserver_title}'],
}
MANIFEST

step 'add create profile manifest to manifest_erb file'
manifest_erb << pp
puts manifest_erb

step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, :manifest => manifest_erb)
inject_site_pp(master, get_site_pp_path(master), site_pp)

# config node scoped variable  manifest
confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    step 'Run puppet agent to create profile: appserver:'
    expect_failure('Expected to fail due to FM-5093, FM-5130, and FM-5150') do
      on(agent, puppet('agent -t'), :acceptable_exit_codes => 1) do |result|
        assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
      end
    end

    step "Verify the node scroped variable is created: LOG_ROOT"
    # Comment out the below line due to FM-5093, FM-5130, and FM-5150
    #wsadmin_tool(agent, "AdminTask.showVariables", "NODE_LOG_ROOT")
  end
end
