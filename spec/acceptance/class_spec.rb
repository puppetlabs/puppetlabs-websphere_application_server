require 'spec_helper_acceptance'
require 'installer_constants'

describe 'Verify the minimum install' do
  context 'that the instance installs and is idempotent' do
    before(:all) do
      @agent = WebSphereHelper.get_dmgr_host
      @manifest = WebSphereInstance.manifest

      runner = BeakerAgentRunner.new
      @result = runner.execute_agent_on(@agent, @manifest)
      @second_result = runner.execute_agent_on(@agent, @manifest)
    end

    it 'class should run successfully' do
      expect([0, 2]).to include(@result.exit_code)
    end

    it 'class should be idempotent' do
      expect(@second_result.exit_code).to eq 0
    end

    it 'shall be installed to the instance directory' do
      rc = WebSphereHelper.remote_dir_exists(@agent, WebSphereConstants.base_dir + '/' + WebSphereConstants.instance_name + '/AppServer')
      expect(rc).to eq 0
    end
  end
  context 'that the dmgr installs and is idempotent' do
    before(:all) do
      @agent = WebSphereHelper.get_dmgr_host
      fail "@agent MUST be set for the websphere class to install" unless @agent.hostname

      @manifest = WebSphereDmgr.manifest(@agent)

      runner = BeakerAgentRunner.new
      @result = runner.execute_agent_on(@agent, @manifest)
      @second_result = runner.execute_agent_on(@agent, @manifest)
    end

    it 'dmgr should run successfully' do
      expect([0, 2]).to include(@result.exit_code)
    end

    it 'dmgr is idempotent' do
      expect(@second_result.exit_code).to eq 0
    end

    it 'shall be installed on the agent' do
      rc = WebSphereHelper.remote_dir_exists(@agent, WebSphereConstants.profile_base)
      expect(rc).to eq 0
    end

    it_behaves_like 'a running dmgr'
  end
end
