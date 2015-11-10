require 'erb'
require 'master_manipulator'
require 'websphere_helper'
test_name 'FM-3808 - C93835 - Declare base class'

# Teardown
teardown do
  confine_block(:except, :roles => %w{master dashboard database}) do
    step 'Uninstall IBM Installation Manager'
    on(agent, "/var/ibm/InstallationManager/uninstall/uninstallc") do |result|
      assert_no_match(/Error/, result.stderr, 'Failed to uninstall IBM Installation Manager')
    end
    on(agent, "rm -rf /opt/IBM")
    on(agent, "rm -rf /opt/log/websphere")
  end
end

pp = <<-MANIFEST
  $base_dir         = '/opt/IBM'
  $user             = 'webadmin'
  $group            = 'webadmins'
  class { 'ibm_installation_manager':
    deploy_source => true,
    source        => 'http://int-resources.ops.puppetlabs.net/QA_resources/ibm_websphere/agent.installer.linux.gtk.x86_64_1.8.3000.20150606_0047.zip',
    target        => '/opt/IBM/InstallationManager',
  }
  # Organizational log locations
  file { [
    '/opt/log',
    '/opt/log/websphere',
    '/opt/log/websphere/appserverlogs',
    '/opt/log/websphere/applogs',
    '/opt/log/websphere/wasmgmtlogs',
  ]:
    ensure => 'directory',
    owner  => $user,
    group  => 'webadmins',
  }
  class { 'websphere_application_server':
    user     => $user,
    group    => $group,
    base_dir => $base_dir,
  }
MANIFEST

step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, :manifest => pp)
inject_site_pp(master, get_site_pp_path(master), site_pp)

step 'Run Puppet Agent to create a websphere instance'
confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    on(agent, puppet('agent -t --graph  --environment production'), :acceptable_exit_codes => [0,2]) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    end
  end
end
