require 'erb'
require 'master_manipulator'
require 'websphere_helper'
require 'installer_constants'

test_name 'FM-5188 - C97900 - Create cluster on aix'

#getting a fresh VM from vmPooler
node_name = get_fresh_node('centos-6-x86_64')

# Teardown
teardown do
  confine_block(:except, :roles => %w{master dashboard database}) do
    agents.each do |agent|
      #comment out due to FM-5130
      #remove_websphere_instance('websphere_application_server', '/opt/log/websphere /opt/IBM')
    end
    return_node_to_pooler(node_name)
  end
end

#Get the ERB manifest:
base_dir                = WebSphereConstants.base_dir
instance_base           = WebSphereConstants.instance_base
profile_base            = WebSphereConstants.profile_base
was_installer           = WebSphereConstants.was_installer
package_name            = WebSphereConstants.package_name
package_version         = WebSphereConstants.package_version
update_package_version  = WebSphereConstants.update_package_version
instance_name           = WebSphereConstants.instance_name
fixpack_installer       = WebSphereConstants.fixpack_installer
java_installer          = WebSphereConstants.java_installer
java_package            = WebSphereConstants.java_package
java_version            = WebSphereConstants.java_version
cell                    = WebSphereConstants.cell
dmgr_title              = WebSphereConstants.dmgr_title
cluster_title           = WebSphereConstants.cluster_title

local_files_root_path = ENV['FILES'] || "tests/beaker/files"
manifest_template     = File.join(local_files_root_path, 'websphere_fixpack_manifest.erb')
manifest_erb          = ERB.new(File.read(manifest_template)).result(binding)

# create appserver profile manifest:
pp = <<-MANIFEST
websphere_application_server::profile::dmgr { '#{dmgr_title}':
  instance_base => "#{instance_base}",
  profile_base  => "#{profile_base}",
  cell          => "#{cell}",
  node_name     => "#{node_name}",
  subscribe     => [
    Ibm_pkg['WebSphere_fixpack'],
    Ibm_pkg['Websphere_Java'],
  ],
}

websphere_application_server::cluster { '#{cluster_title}':
  profile_base => "#{profile_base}",
  dmgr_profile => "#{dmgr_title}",
  cell         => "#{cell}",
  require      => Websphere_application_server::Profile::Dmgr['#{dmgr_title}'],
}
MANIFEST

step 'add create profile manifest to manifest_erb file'
manifest_erb << pp

step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, :manifest => manifest_erb)
inject_site_pp(master, get_site_pp_path(master), site_pp)

# create cluster
confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    step 'Run puppet agent to create profile: appserver:'
    expect_failure('Expected to fail due to FM-5093, FM-5130, FM-5150, and FM-5211') do
      on(agent, puppet('agent -t'), :acceptable_exit_codes => 1) do |result|
        assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
      end
    end

    step 'Verify if the cluster exists'
    # Comment out the below line due to FM-5122
    #verify_cluster(agent, cluster_title)
  end
end
