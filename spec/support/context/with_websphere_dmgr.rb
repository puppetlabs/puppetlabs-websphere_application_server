require 'spec_helper_acceptance'
require 'installer_constants'

shared_context 'with a websphere dmgr' do
  before(:all) do
    hostname = WebSphereHelper.get_master
    @manifest = <<-MANIFEST
      ## Create a DMGR Profile
      #{WebSphereConstants.class_name}::profile::dmgr { '#{WebSphereConstants.dmgr_title}':
        instance_base => '#{WebSphereConstants.instance_base}',
        profile_base  => '#{JDBCProviderConstants.profile_base}',
        cell          => '#{JDBCProviderConstants.cell}',
        node_name     => '#{hostname}',
        user          => '#{WebSphereConstants.user}',
        group         => '#{WebSphereConstants.group}',
      }

      ## Create a cluster
      #{WebSphereConstants.class_name}::cluster { '#{WebSphereCluster.cluster_name}':
        profile_base => '#{WebSphereConstants.profile_base}',
        dmgr_profile => '#{WebSphereConstants.dmgr_title}',
        cell         => '#{WebSphereConstants.cell}',
        user         => '#{WebSphereConstants.user}',
        require      => Websphere_application_server::Profile::Dmgr['#{WebSphereConstants.dmgr_title}'],
      }
    MANIFEST
    @result = WebSphereHelper.agent_execute(@manifest)
  end

  it 'should run successfully' do
    expect(@result.exit_code).to eq 2
  end
end
