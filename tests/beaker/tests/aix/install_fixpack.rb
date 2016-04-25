require 'erb'
require 'master_manipulator'
require 'websphere_helper'
require 'installer_constants'
test_name 'FM-5141 - C97867 - Install IBM fixpacks on aix'

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
base_dir                = Object.const_get('BASE_DIR')
instance_base           = Object.const_get('INSTANCE_BASE')
profile_base            = Object.const_get('PROFILE_BASE')
was_installer           = Object.const_get('WAS_INSTALLER')
package_name            = Object.const_get('PACKAGE_NAME')
package_version         = Object.const_get('PACKAGE_VERSION')
update_package_version  = Object.const_get('UPDATE_PACKAGE_VERSION')
instance_name           = Object.const_get('INSTANCE_NAME')
fixpack_installer       = Object.const_get('FP_INSTALLER')
java_installer          = Object.const_get('JAVA_INSTALLER')
java_package            = Object.const_get('JAVA_PACKAGE')
java_version            = Object.const_get('JAVA_VERSION')

local_files_root_path = ENV['FILES'] || "tests/beaker/files"
manifest_template     = File.join(local_files_root_path, 'websphere_fixpack_manifest.erb')
manifest_erb          = ERB.new(File.read(manifest_template)).result(binding)

puts "manifest erb \n#{manifest_erb}"
step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, :manifest => manifest_erb)
inject_site_pp(master, get_site_pp_path(master), site_pp)

step 'Run Puppet Agent to install fixpackes:'
confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    expect_failure('Expected to fail due to FM-5093, FM-5130, and FM-5150') do
      on(agent, puppet('agent -t'), :acceptable_exit_codes => 1) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
      end
    end

    step "Verify fixpack is installed: new version of WebSphere: #{update_package_version}"
    command = "#{instance_base}/bin/versionInfo.sh"
    # Comment out the below line due to FM-5093, FM-5130, and FM-5150
    #verify_websphere(agent, command, update_package_version)

    step "Verify fixpack is installed: Java #{java_version}"
    command = "#{instance_base}/java/bin/java --fullversion"
    # Comment out the below line due to FM-5093, FM-5130, and FM-5150
    #verify_websphere(agent, command, java_version)
  end
end
