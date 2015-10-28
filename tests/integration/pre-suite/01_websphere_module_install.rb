test_name 'FM-3804 - Cxx - Plug-in Sync Module from Master with Prerequisites Satisfied on Agent'

# step 'Install Module via PMT'
# stub_forge_on(master)

step 'Install concat and ibm_installation_manager'

on(master, puppet('module install joshbeard-ibm_installation_manager'))

step 'Install websphere Module'
on(master, puppet('module install puppetlabs-concat'))

#on(master, puppet('module install puppetlabs-websphere_application_server'))
#on(master, puppet('module install joshbeard-websphere'))

