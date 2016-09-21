ENV['WEBSPHERE_NODES_REQUIRED'] = 'master dmgr'

require 'spec_helper_acceptance'
require 'installer_constants'

require 'pry'

describe 'Install the websphere dmgr' do
  before(:all) do
    @agent = WebSphereHelper.get_dmgr_host
    WebSphereInstance.install(@agent)
    WebSphereDmgr.install(@agent)
  end

  it 'should be installed' do
      expect(WebSphereHelper.remote_file_exists(@agent, WebSphereConstants.dmgr_status))
      expect(WebSphereHelper.remote_file_exists(@agent, WebSphereConstants.ws_admin))
  end

  it_behaves_like 'a running dmgr'

  context 'should stop the dmgr service' do
    before(:all) do
      @manifest = <<-MANIFEST
      websphere_application_server::profile::service { '#{WebSphereConstants.dmgr_title}':
        type         => 'dmgr',
        ensure       => 'stopped',
        profile_base => '#{WebSphereConstants.profile_base}',
        user         => '#{WebSphereConstants.user}',
      }
      MANIFEST
      runner = BeakerAgentRunner.new
      @result = runner.execute_agent_on(@agent, @manifest)
    end

    it 'should run without errors' do
      expect(@result.exit_code).to eq 2
    end

    it_behaves_like 'an idempotent resource'
    it_behaves_like 'a stopped dmgr'
  end

  context 'should start the dmgr service' do
    before(:all) do
      @manifest = <<-MANIFEST
      websphere_application_server::profile::service { '#{WebSphereConstants.dmgr_title}':
        type         => 'dmgr',
        ensure       => 'running',
        profile_base => '#{WebSphereConstants.profile_base}',
        user         => '#{WebSphereConstants.user}',
      }
      MANIFEST
      runner = BeakerAgentRunner.new
      @result = runner.execute_agent_on(@agent, @manifest)
    end

    it 'should run without errors' do
      expect(@result.exit_code).to eq 2
    end

    it_behaves_like 'an idempotent resource'
    it_behaves_like 'a running dmgr'
  end
end
