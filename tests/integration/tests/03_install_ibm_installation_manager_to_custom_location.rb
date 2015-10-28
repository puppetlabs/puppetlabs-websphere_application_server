#require 'erb'
require 'master_manipulator'
test_name 'FM-3804 - C93831 - Install Installation Manager to a custom location'

custom_location = '/opt/custom_location'

# Teardown
teardown do
  confine_block(:except, :roles => %w{master dashboard database frictionless}) do
    on(agent, "/var/ibm/InstallationManager/uninstall/uninstallc") do |result|
      assert_no_match(/Error/, result.stderr, 'Failed to uninstall IBM Installation Manager')
    end
    on(agent, "rm -rf /opt/IBM")
  end
end

pp = <<-MANIFEST
class { 'ibm_installation_manager':
    deploy_source => true,
    source        => 'http://int-resources.ops.puppetlabs.net/QA_resources/ibm_websphere/agent.installer.linux.gtk.x86_64_1.8.3000.20150606_0047.zip',
    target        =>  "#{custom_location}"
}
MANIFEST

step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, :manifest => pp)
inject_site_pp(master, get_site_pp_path(master), site_pp)

step 'Run Puppet Agent to install IBM Installation Manager to a custom location'
confine_block(:except, :roles => %w{master dashboard database frictionless}) do
  agents.each do |agent|
    on(agent, puppet('agent -t --environment production'), :acceptable_exit_codes => [0,2]) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    end

    verify_im_installed?(custom_location)
  end
end