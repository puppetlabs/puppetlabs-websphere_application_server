require 'spec_helper_acceptance'

describe 'add cluster members' do
  before(:all) do
    runner = BeakerAgentRunner.new

    @dmgragent = WebSphereHelper.dmgr_host
    @appagent = WebSphereHelper.app_host
    @webspheremanifest = WebSphereInstance.manifest
    [@dmgragent, @appagent].each do |agent|
      runner.execute_agent_on(agent, @webspheremanifest)
    end

    @dmgrmanifest = WebSphereDmgr.manifest(target_agent: @dmgragent)
    @appmanifest = WebSphereAppServer.manifest(@appagent, @dmgragent)

    @member1 = WebSphereHelper.fresh_node('redhat-7-x86_64')
    @member2 = WebSphereHelper.fresh_node('centos-6-x86_64')
    @member3 = WebSphereHelper.fresh_node('centos-6-x86_64')

    @execute_hash = { @dmgragent => @dmgrmanifest, @appagent => @appmanifest }
    @site_pp = runner.generate_site_pp(@execute_hash)
    runner.copy_site_pp(@site_pp)
    @dmgr_result = runner.execute_agent_on(@dmgragent)
    @dmgr_result2 = runner.execute_agent_on(@dmgragent)
    @app_result = runner.execute_agent_on(@appagent)
    @app_result2 = runner.execute_agent_on(@appagent)
  end

  it 'installs dmgr' do
    expect(@dmgr_result.exit_code).to eq 2
  end

  it 'installs dmgr a second time' do
    expected = [0, 2]
    expect(expected).to include(@dmgr_result2.exit_code)
  end

  it 'installs appserver' do
    expect(@app_result.exit_code).to eq 2
  end

  it 'installs appserver a second time' do
    expected = [0, 2]
    expect(expected).to include(@app_result2.exit_code)
  end
end
