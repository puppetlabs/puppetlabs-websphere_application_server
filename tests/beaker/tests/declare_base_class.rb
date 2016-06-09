require 'erb'
require 'master_manipulator'
require 'websphere_helper'
require 'installer_constants'
test_name 'FM-5068 - C97833 - Declare base class on aix'

# Teardown
teardown do
  confine_block(:except, :roles => %w{master dashboard database}) do
    agents.each do |agent|
      #comment out due to FM-5093
      #remove_websphere('websphere_application_server')
    end
    on(agent, "rm -rf /opt/log/websphere", :acceptable_exit_codes => [0,127])
  end
end

base_dir  = WebSphereConstants.base_dir
user      = WebSphereConstants.user
group     = WebSphereConstants.group

pp = <<-MANIFEST
  # Organizational log locations
  file { [
    '/opt/log',
    '/opt/log/websphere',
    '/opt/log/websphere/appserverlogs',
    '/opt/log/websphere/applogs',
    '/opt/log/websphere/wasmgmtlogs',
  ]:
    ensure => 'directory',
    owner  => "#{user}",
    group  => "#{group}",
  }
  class { 'websphere_application_server':
    user     => "#{user}",
    group    => "#{group}",
    base_dir => "#{base_dir}",
  }
MANIFEST

step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, :manifest => pp)
inject_site_pp(master, get_site_pp_path(master), site_pp)

step 'Run Puppet Agent to declare base class'
confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    expect_failure('expected to fail due to FM-5093') do
      on(agent, puppet('agent -t'), :acceptable_exit_codes => [1,4,6]) do |result|
        assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
      end
    end

    step 'Verify the files/directories are created:'
    files = ['/opt', '/opt/IBM', 'opt/log', '/opt/log/websphere', '/opt/log/websphere/appserverlogs',
            '/opt/log/websphere/applogs','/opt/log/websphere/wasmgmtlogs']
    #verify_file_exist?(files)

    step 'Verify if user and group are created:'
    expect_failure('expected to fail due to FM-5093') do
      on(agent,  "cat /etc/passwd | grep webadmin", :acceptable_exit_codes => [1]) do |result|
        assert_match(/webadmin/, result.stdout, 'Unexpected error was detected!')
      end
    end
    expect_failure('expected to fail due to FM-5093') do
      on(agent,  "cat /etc/group | grep webadmins", :acceptable_exit_codes => [1]) do |result|
        assert_match(/webadmins/, result.stdout, 'Unexpected error was detected!')
      end
    end
  end
end
