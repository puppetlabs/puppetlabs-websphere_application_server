require 'erb'
require 'master_manipulator'

require 'websphere_helper'
test_name 'FM-3808 - C93835 - Declare base class'
test_name 'FM-3808 - C93836 - Create a websphere instance'
test_name 'FM-3808 - C93837 - Install IBM fix patches'

# Teardown
teardown do
  confine_block(:except, :roles => %w{master dashboard database}) do
    on(agent, "/var/ibm/InstallationManager/uninstall/uninstallc") do |result|
      assert_no_match(/Error/, result.stderr, 'Failed to uninstall IBM Installation Manager')
    end
    on(agent, "rm -rf /opt/IBM")
  end
end

pp = <<-MANIFEST
  $base_dir         = '/opt/IBM'
  $instance_name    = 'WebSphere85'
  $instance_base    = "${base_dir}/${instance_name}/AppServer"
  $profile_base     = "${instance_base}/profiles"
  $was_installer    = '/ibminstallers/ibm/ndtrial'
  $package_name     = 'com.ibm.websphere.NDTRIAL.v85'
  $package_version  = '8.5.5000.20130514_1044'
  $user             = 'webadmin'
  $group            = 'webadmins'
  $java7_installer  = '/ibminstallers/ibm/java7'
  $java7_package    = 'com.ibm.websphere.IBMJAVA.v71'
  $java7_version    = '7.1.2000.20141116_0823'
  # Declare the IBM Installation Manager class. Make sure IM is installed.
  # We want to install it to /opt/IBM/InstallationManager
  # We have it downloaded and extracted under /ibminstallers/ibm/IM
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
    owner  => 'webadmin',
    group  => 'webadmins',
  }
  # Base stuff for WebSphere.  Specify a common user/group and the base
  # directory to where we want things to live.  Make sure the
  # InstallationManager is managed before we do this.
  class { 'websphere_application_server':
    user     => 'webadmin',
    group    => 'webadmins',
    base_dir => '/opt/IBM',
  }
  websphere_application_server::instance { 'WebSphere85':
    target       => $instance_base,
    package      => $package_name,
    version      => $package_version,
    profile_base => $profile_base,
    repository   => "${was_installer}/repository.configs",
    user         => $user,
    group        => $group,
  }
  ibm_pkg { 'WebSphere_8554_fixpack':
    ensure        => 'present',
    package       => $package_name,
    version       => '8.5.5004.20141119_1746',
    repository    => '/ibminstallers/ibm/FP04/repository.configs',
    target        => $instance_base,
    package_owner => $user,
    package_group => $group,
    require       => Websphere_application_server::Instance['WebSphere85'],
  }
  ibm_pkg { 'Websphere85_Java7':
    ensure        => 'present',
    package       => $java7_package,
    version       => $java7_version,
    repository    => "${java7_installer}/repository.configs",
    target        => $instance_base,
    package_owner => $user,
    package_group => $group,
    require       => Ibm_pkg['WebSphere_8554_fixpack'],
  }
MANIFEST

step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, :manifest => pp)
inject_site_pp(master, get_site_pp_path(master), site_pp)

step 'Run Puppet Agent to create a websphere instance'
confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    step 'Expect this to fail'
    expect_failure('Expected to fail due to websphere module is not really ready for testing') do
      on(agent, puppet('agent -t --environment production'), :acceptable_exit_codes => [0,2]) do |result|
        assert_match(/Error:/, result.stderr, 'Unexpected error was detected!')
      end
    end
  end
end
