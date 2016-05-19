test_name 'FM-3808 - C94731 - Plug-in Sync Module from Master with Prerequisites Satisfied on Agent'

step 'Install puppetlabs-websphere_application_server Module Dependencies'
%w(puppet-archive puppetlabs-stdlib puppetlabs-concat puppetlabs-ibm_installation_manager).each do |dep|
  on(master, puppet("module install #{dep}"))
end

step 'Install ibm_installation_manager Module'
proj_root = File.expand_path(File.join(File.dirname(__FILE__), '../../../'))
staging = { :module_name => 'puppetlabs-websphere_application_server' }
local = { :module_name => 'websphere_application_server', :source => proj_root, :target_module_path => '/etc/puppetlabs/code/environments/production/modules' }

# in CI install from staging forge, otherwise from local
install_dev_puppet_module_on(master, options[:forge_host] ? staging : local)
