require 'spec_helper_acceptance'
require 'installer_constants'

describe 'Install the websphere dmgr' do
  before(:all) do
    @agent = WebSphereHelper.get_dmgr_host
    WebSphereInstance.install(@agent) # run puppet agent with rendered spec/acceptance/fixtures/websphere_class.erb
    WebSphereDmgr.install(@agent) # run puppet agent with rendered spec/acceptance/fixtures/websphere_dmgr.erb
  end

  it 'should be installed' do
    expect(WebSphereHelper.remote_file_exists(@agent, WebSphereConstants.dmgr_status)) # check for base_dir/profiles/PROFILE_DMGR_02/bin/serverStatus.sh
    expect(WebSphereHelper.remote_file_exists(@agent, WebSphereConstants.ws_admin)) # check for base_dir/profiles/PROFILE_DMGR_02/bin/wsadmin.sh
  end

  it_behaves_like 'a running dmgr'

  context 'should stop the dmgr service' do
    before(:all) do
      @manifest = <<-MANIFEST
      websphere_application_server::profile::service { '#{WebSphereConstants.dmgr_title}': # PROFILE_DMGR_02
        type         => 'dmgr',
        ensure       => 'stopped',
        profile_base => '#{WebSphereConstants.profile_base}', # /home/webadmin/IBM/profiles
        user         => '#{WebSphereConstants.user}', # webadmin
      }
      MANIFEST
      runner = BeakerAgentRunner.new
      @result = runner.execute_agent_on(@agent, @manifest) # run above manifest on dmgr host
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
