require 'spec_helper_acceptance'
require 'installer_constants'

describe 'add cluster members' do
  before(:all) do
    @dmgragent = WebSphereHelper.get_dmgr_host
    @appagent = WebSphereHelper.get_app_host
    WebSphereInstance.install(@dmgragent)
    WebSphereInstance.install(@appagent)
    @dmgrmanifest = WebSphereDmgr.manifest(@dmgragent)
    @appmanifest = WebSphereAppServer.manifest(@appagent, @dmgragent)

    @member1 = WebSphereHelper.get_fresh_node('redhat-7-x86_64')
    @member2 = WebSphereHelper.get_fresh_node('centos-6-x86_64')
    @member3 = WebSphereHelper.get_fresh_node('centos-6-x86_64')

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
    require 'pry'; binding.pry
    expect(@dmgr_result.exit_code).to eq 0
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
