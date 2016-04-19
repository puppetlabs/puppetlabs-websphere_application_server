require 'erb'
require 'master_manipulator'
require 'websphere_helper'
test_name 'FM-5120 - C97842 - create websphere instance on aix'

# Teardown
teardown do
  confine_block(:except, :roles => %w{master dashboard database}) do
    agents.each do |agent|
      #comment out due to FM-5130
      #remove_websphere_instance('websphere_application_server', '/opt/log/websphere /opt/IBM')
    end
  end
end

local_files_root_path = ENV['FILES'] || "files"
manifest_template     = File.join(local_files_root_path, 'websphere_instance_manifest.erb')
manifest_erb          = ERB.new(File.read(manifest_template)).result(binding)

step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, :manifest => manifest_erb)
inject_site_pp(master, get_site_pp_path(master), site_pp)

step 'Run Puppet Agent to create a websphere instance'
confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    on(agent, puppet('agent -t'), :acceptable_exit_codes => 1) do |result|
      expect_failure('Expected to fail due FM-5130') do
        assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
      end
    end
    step 'Verify websphere instance is created:'
    # Comment out the below line due to FM-5130
    #verify_websphere_created?(agent, 'WebSphere85')
  end
end
