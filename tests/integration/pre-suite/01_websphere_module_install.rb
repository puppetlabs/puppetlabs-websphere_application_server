test_name 'FM-3808 - C94731 - Plug-in Sync Module from Master with Prerequisites Satisfied on Agent'

# step 'Install Module via PMT'
# stub_forge_on(master)

#Currently the puppetlabs-ibm_installation_manager is not ready for testing, so using joshbeard-ibm_installation_manager
# instead.
step 'Install joshbeard-ibm_installation_manager'
on(master, puppet('module install joshbeard-ibm_installation_manager'))

step 'Install puppetlabs-websphere_application_server Module Dependencies'
on(master, puppet('module install nanliu-staging'))
on(master, puppet('module install puppetlabs-stdlib'))
on(master, puppet('module install puppetlabs-concat'))

step 'Install ibm_installation_manager Module'
proj_root = File.expand_path(File.join(File.dirname(__FILE__), '../../../'))
staging = { :module_name => 'puppetlabs-websphere_application_server' }
local = { :module_name => 'websphere_application_server', :source => proj_root, :target_module_path => master['distmoduledir'] }

# in CI install from staging forge, otherwise from local
install_dev_puppet_module_on(master, options[:forge_host] ? staging : local)

step 'Install dsestero/download_uncompress module on the agent'
confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    on(agent, puppet('module install dsestero-download_uncompress'))
  end
end

