require 'master_manipulator'
require 'websphere_helper'

test_name 'FM-5068 - C97836 - Mapping NFS drive and install IBM Installation Manager'

pp = <<-MANIFEST
file {"/mnt/QA_resources":
  ensure => "directory",
}
mount { "/mnt/QA_resources":
  device  => "int-resources.ops.puppetlabs.net:/tank01/resources0/QA_resources",
  fstype  => "nfs",
  ensure  => "mounted",
  options => "defaults",
  atboot  => true,
}
->
class { 'ibm_installation_manager':
  deploy_source => true,
  group         => 'system',
  source        => '/mnt/QA_resources/ibm_websphere/agent.installer.aix.gtk.ppc_1.8.4000.20151125_0201.zip',
  target        => '/opt/IBM/InstallationManager',
}
MANIFEST

step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, :manifest => pp)
inject_site_pp(master, get_site_pp_path(master), site_pp)

step 'Run Puppet Agent to map NFS and install IM:'
confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    on(agent, puppet('agent -t'), :acceptable_exit_codes => [0,2]) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    end
  end
end
