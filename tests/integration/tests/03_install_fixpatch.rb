require 'erb'
require 'master_manipulator'
require 'websphere_helper'
test_name 'FM-3808 - C93837 - Install IBM fix patches'

# Teardown
teardown do
  # Commenting the teardown because the websphere module is not ready for testing yet,
  # therefore no websphere instance is created yet, teardown will fail
  # All teardown line of codes will be uncommented when the module is ready for test.
  # confine_block(:except, :roles => %w{master dashboard database}) do
  #   step 'Uninstall IBM Installation Manager'
  #   on(agent, "/var/ibm/InstallationManager/uninstall/uninstallc") do |result|
  #     assert_no_match(/Error/, result.stderr, 'Failed to uninstall IBM Installation Manager')
  #   end
  #   on(agent, "rm -rf /opt/IBM")
  # end
end

local_files_root_path = ENV['FILES'] || "tests/files"
manifest_template     = File.join(local_files_root_path, 'websphere_fixpatch_manifest.erb')
manifest_erb          = ERB.new(File.read(manifest_template)).result(binding)

step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, :manifest => manifest_erb)
inject_site_pp(master, get_site_pp_path(master), site_pp)

step 'Run Puppet Agent to create a websphere instance'
confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    on(agent, puppet('agent -t --environment production'), :acceptable_exit_codes => [1]) do |result|
      expect_failure('Expected to fail due to websphere module is not really ready for testing') do
        assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
      end
    end
  end
end
