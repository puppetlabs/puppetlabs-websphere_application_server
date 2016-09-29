require 'spec_helper_acceptance'
require 'installer_constants'

describe 'add cluster members' do
  before(:all) do
    @dmgragent = WebSphereHelper.get_dmgr_host
    @appagent = WebSphereHelper.get_app_host
    WebSphereInstance.install(@dmgragent)
    WebSphereInstance.install(@appagent)
    @dmgrmanifest = WebSphereDmgr.manifest(@dmgragent)

    @dmgrhostname = @dmgragent.hostname
    @apphostname = @appagent.hostname
    @member1 = WebSphereHelper.get_fresh_node('redhat-7-x86_64')
    @member2 = WebSphereHelper.get_fresh_node('centos-6-x86_64')
    @member3 = WebSphereHelper.get_fresh_node('centos-6-x86_64')
  end

  describe "without exported resources" do
    before(:all) do
      @appmanifest = <<-MANIFEST
        ## Create  Application Server Profiles
        #{WebSphereConstants.class_name}::profile::appserver {"#{WebSphereConstants.appserver_title}_explicitly":
          instance_base => '#{WebSphereConstants.instance_base}',
          profile_base  => '#{JDBCProviderConstants.profile_base}',
          cell          => '#{JDBCProviderConstants.cell}',
          template_path => "#{WebSphereConstants.instance_base}/profileTemplates/managed",
          dmgr_host     => "#{@dmgrhostname}",
          node_name     => "#{@apphostname}",
          user          => '#{WebSphereConstants.user}',
          group         => '#{WebSphereConstants.group}',
        }
        ->
        ## Create a cluster member explicitly
        #{WebSphereConstants.class_name}::cluster::member { "#{WebSphereConstants.appserver_title}_explicitly":
          ensure       => 'present',
          cluster      => "#{WebSphereCluster.cluster_name}",
          node_name    => "#{@apphostname}",
          cell         => "#{WebSphereConstants.cell}",
          profile_base => "#{WebSphereConstants.profile_base}",
          dmgr_profile => "#{WebSphereConstants.dmgr_title}",
        }
      MANIFEST

      @execute_hash = { @dmgragent => @dmgrmanifest, @appagent => @appmanifest }
      runner = BeakerAgentRunner.new
      @site_pp = runner.generate_site_pp(@execute_hash)
      runner.copy_site_pp(@site_pp)
      @dmgr_result = runner.execute_agent_on(@dmgragent)
      @dmgr_result2 = runner.execute_agent_on(@dmgragent)
      @app_result = runner.execute_agent_on(@appagent)
      @app_result2 = runner.execute_agent_on(@appagent)
    end

    it "installs dmgr" do
      expect(@dmgr_result.exit_code).to eq 2
    end

    it "installs dmgr a second time" do
      expect([0, 2]).to include(@app_result2.exit_code)
    end

    it "installs appserver" do
      expect(@app_result.exit_code).to eq 2
    end

    it "installs appserver a second time" do
      expect([0, 2]).to include(@app_result2.exit_code)
    end
  end
end
