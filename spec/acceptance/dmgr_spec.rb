require 'spec_helper_acceptance'
require 'installer_constants'

describe 'Install the websphere dmgr' do
  before(:all) do
    @agent = WebSphereHelper.dmgr_host
    WebSphereInstance.install(@agent)
    WebSphereDmgr.install(@agent)
  end

  it 'is installed' do
    expect(WebSphereHelper.remote_file_exists(@agent, WebSphereConstants.dmgr_status)) # rubocop:disable RSpec/VoidExpect
    expect(WebSphereHelper.remote_file_exists(@agent, WebSphereConstants.ws_admin)) # rubocop:disable RSpec/VoidExpect
  end

  it_behaves_like 'a running dmgr', WebSphereConstants.profile_base, WebSphereConstants.dmgr_title

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

    it 'runs without errors' do
      expect(@result.exit_code).to eq 2
    end

    it_behaves_like 'an idempotent resource'
    it_behaves_like 'a stopped dmgr', WebSphereConstants.profile_base, WebSphereConstants.dmgr_title
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

    it 'runs without errors' do
      expect(@result.exit_code).to eq 2
    end

    it_behaves_like 'an idempotent resource'
    it_behaves_like 'a running dmgr', WebSphereConstants.profile_base, WebSphereConstants.dmgr_title
  end
end
