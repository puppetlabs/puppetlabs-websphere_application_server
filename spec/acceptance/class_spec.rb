# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'Verify the minimum install' do
  context 'as root user' do
    let(:base_dir) { '/opt/IBM' }
    let(:instance_base) { "#{base_dir}/#{WebSphereConstants.instance_name}/AppServer" }
    let(:profile_base) { "#{instance_base}/profiles" }
    let(:dmgr_profile) { "#{profile_base}/#{WebSphereConstants.dmgr_title}" }

    context 'that the instance installs and is idempotent' do
      before(:all) do
        @agent = WebSphereHelper.dmgr_host
        @manifest = WebSphereInstance.manifest

        runner = LitmusAgentRunner.new
        @result = runner.execute_agent_on(@agent, @manifest)
        @second_result = runner.execute_agent_on(@agent, @manifest)
      end

      it 'class should run successfully' do
        expected = [0, 2]
        expect(expected).to include(@result.exit_code)
      end

      it 'class should be idempotent' do
        expect(@second_result.exit_code).to eq 0
      end

      it 'shall be installed to the instance directory' do
        rc = WebSphereHelper.remote_dir_exists(@agent, instance_base)
        expect(rc).to eq 0
      end
    end
    context 'that the dmgr installs and is idempotent' do
      before(:all) do
        @agent = WebSphereHelper.dmgr_host
        raise '@agent MUST be set for the websphere class to install' unless @agent.hostname
        @manifest = WebSphereDmgr.manifest(target_agent: @agent)

        runner = LitmusAgentRunner.new
        @result = runner.execute_agent_on(@agent, @manifest)
        @second_result = runner.execute_agent_on(@agent, @manifest)
      end

      it 'dmgr should run successfully' do
        expected = [0, 2]
        expect(expected).to include(@result.exit_code)
      end

      it 'dmgr is idempotent' do
        expect(@second_result.exit_code).to eq 0
      end

      it 'shall be installed on the agent' do
        rc = WebSphereHelper.remote_dir_exists(@agent, @profile_base)
        expect(rc).to eq 0
      end

      it 'profile binaries are present' do
        ["#{dmgr_profile}/bin/startServer.sh",
         "#{dmgr_profile}/bin/stopServer.sh",
         "#{dmgr_profile}/bin/manageprofiles.sh"].each do |bin|
          expect(WebSphereHelper.remote_file_exists(@agent, bin)).to eq 0
        end
      end

      after(:all) do
        manifest = WebSphereHelper.stop_server(server_name: 'dmgr',
                                               user: 'root',
                                               profile_base: '/opt/IBM/WebSphere85/AppServer/profiles',
                                               profile_name: 'PROFILE_DMGR_02')
        runner = LitmusAgentRunner.new
        runner.execute_agent_on(@agent, manifest)
      end

      it_behaves_like 'a running dmgr', '/opt/IBM/WebSphere85/AppServer/profiles', WebSphereConstants.dmgr_title
    end
  end

  context 'as nonadministrator' do
    let(:base_dir) { '/home/webadmin/IBM' }
    let(:instance_base) { "#{base_dir}/#{WebSphereConstants.instance_name}/AppServer" }
    let(:profile_base) { "#{instance_base}/profiles" }
    let(:dmgr_profile) { "#{profile_base}/#{WebSphereConstants.dmgr_title}" }

    context 'that the instance installs and is idempotent' do
      before(:all) do
        @agent = WebSphereHelper.dmgr_host
        @manifest = WebSphereInstance.manifest(base_dir: '/home/webadmin/IBM')

        runner = LitmusAgentRunner.new
        @result = runner.execute_agent_on(@agent, @manifest)
        @second_result = runner.execute_agent_on(@agent, @manifest)
      end

      it 'class should run successfully' do
        expected = [0, 2]
        expect(expected).to include(@result.exit_code)
      end

      it 'class should be idempotent' do
        expect(@second_result.exit_code).to eq 0
      end

      it 'shall be installed to the instance directory' do
        rc = WebSphereHelper.remote_dir_exists(@agent, instance_base)
        expect(rc).to eq 0
      end
    end
    context 'that the dmgr installs and is idempotent' do
      before(:all) do
        @agent = WebSphereHelper.dmgr_host
        raise '@agent MUST be set for the websphere class to install' unless @agent.hostname
        @manifest = WebSphereDmgr.manifest(target_agent: @agent,
                                           base_dir: '/home/webadmin/IBM')

        runner = LitmusAgentRunner.new
        @result = runner.execute_agent_on(@agent, @manifest)
        @second_result = runner.execute_agent_on(@agent, @manifest)
      end

      it 'dmgr should run successfully' do
        expected = [0, 2]
        expect(expected).to include(@result.exit_code)
      end

      it 'dmgr is idempotent' do
        expect(@second_result.exit_code).to eq 0
      end

      it 'shall be installed on the agent' do
        rc = WebSphereHelper.remote_dir_exists(@agent, @profile_base)
        expect(rc).to eq 0
      end

      it 'profile binaries are present' do
        ["#{dmgr_profile}/bin/startServer.sh",
         "#{dmgr_profile}/bin/stopServer.sh",
         "#{dmgr_profile}/bin/manageprofiles.sh"].each do |bin|
          expect(WebSphereHelper.remote_file_exists(@agent, bin)).to eq 0
        end
      end

      it_behaves_like 'a running dmgr', '/home/webadmin/IBM/WebSphere85/AppServer/profiles', WebSphereConstants.dmgr_title

      after(:all) do
        manifest = WebSphereHelper.stop_server(server_name: 'dmgr',
                                               user: 'webadmin',
                                               profile_base: '/home/webadmin/IBM/WebSphere85/AppServer/profiles',
                                               profile_name: 'PROFILE_DMGR_02')
        runner = LitmusAgentRunner.new
        runner.execute_agent_on(@agent, manifest)
      end
    end
  end
end
