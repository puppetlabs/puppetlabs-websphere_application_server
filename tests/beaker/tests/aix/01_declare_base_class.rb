require 'erb'
require 'master_manipulator'
require 'websphere_helper'
test_name 'FM-5068 - C97833 - Declare base class on aix'

# Teardown
teardown do
  confine_block(:except, :roles => %w{master dashboard database}) do
    step 'Uninstall IBM Installation Manager'
    on(agent, "/var/ibm/InstallationManager/uninstall/uninstallc", :acceptable_exit_codes => [0,127]) do |result|
      assert_no_match(/Error/, result.stderr, 'Failed to uninstall IBM Installation Manager')
    end
    on(agent, "rm -rf /opt/test/IBM", :acceptable_exit_codes => [0,127])
    on(agent, "rm -rf /opt/test/log/websphere", :acceptable_exit_codes => [0,127])
    # on(agent, "umount /mnt/QA_resources", :acceptable_exit_codes => [0,127])
    # on(agent, "rm -rf /mnt/QA_resources", :acceptable_exit_codes => [0,127])
  end
end

pp = <<-MANIFEST
  $base_dir         = '/opt/IBM'
  $user             = 'webadmin'
  $group            = 'webadmins'
  class { 'ibm_installation_manager':
    deploy_source => true,
    source        => '/mnt/QA_resources/ibm_websphere/agent.installer.aix.gtk.ppc_1.8.4000.20151125_0201.zip',
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
    group  => $group,
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

step 'Run Puppet Agent to declare base class'
confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    expect_failure('expected to fail due to FM-5093') do
      on(agent, "/opt/puppetlabs/puppet/bin/puppet agent -t", :acceptable_exit_codes => [1,4,6]) do |result|
        assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
      end
    end

    step 'Verify the files/directories are created:'
    files = ['/opt', '/opt/IBM', 'opt/log', '/opt/log/websphere', '/opt/log/websphere/appserverlogs',
            '/opt/log/websphere/applogs','/opt/log/websphere/wasmgmtlogs']
    #commented out the below line due to FM-5093
    #verify_file_exist?(files)

    step 'Verify if user and group are created:'
    #on(agent,  "cat /etc/passwd | grep webadmin")
    #on(agent, "cat /etc/group | grep webadmins")
  end
end
