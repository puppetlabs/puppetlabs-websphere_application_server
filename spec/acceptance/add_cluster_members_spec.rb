# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'add cluster members', :integration do
  before(:all) do
    runner = LitmusAgentRunner.new

    @dmgragent = WebSphereHelper.dmgr_host
    @appagent = WebSphereHelper.app_host
    @webspheremanifest = WebSphereInstance.manifest
    [@dmgragent, @appagent].each do |agent|
      stdout = runner.execute_agent_on(agent, @webspheremanifest)
      log_stdout(stdout.stdout) unless [0, 2].include?(stdout.exit_code)
    end

    @dmgrmanifest = WebSphereDmgr.manifest(target_agent: @dmgragent)
    @appmanifest = WebSphereAppServer.manifest(@appagent, @dmgragent)
    @execute_hash = { @dmgragent => @dmgrmanifest, @appagent => @appmanifest }
    @site_pp = runner.generate_site_pp(@execute_hash)
    runner.copy_site_pp(@site_pp)
    @dmgr_result = runner.execute_agent_on(@dmgragent)
    log_stdout(@dmgr_result.stdout) unless [0, 2].include?(@dmgr_result.exit_code)
    @dmgr_result2 = runner.execute_agent_on(@dmgragent)
    log_stdout(@dmgr_result2.stdout) unless [0, 2].include?(@dmgr_result2.exit_code)
    @app_result = runner.execute_agent_on(@appagent)
    log_stdout(@app_result.stdout) unless [0, 2].include?(@app_result.exit_code)
    @app_result2 = runner.execute_agent_on(@appagent)
    log_stdout(@app_result2.stdout) unless [0, 2].include?(@app_result2.exit_code)
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
