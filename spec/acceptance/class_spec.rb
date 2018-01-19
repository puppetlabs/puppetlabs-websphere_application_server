require 'spec_helper_acceptance'
require 'installer_constants'

describe 'Verify the minimum install' do
  let(:agent) { WebSphereHelper.get_dmgr_host } # gets beaker host with 'dmgr' role

  context 'that the instance installs and is idempotent' do
    context 'with root user' do
      let(:manifest) { WebSphereInstance.manifest(base_dir: '/opt/IBM') } # returns rendered spec/acceptance/fixtures/websphere_class.erb
      let(:runner) { BeakerAgentRunner.new }
      let(:result) {
        WebSphereHelper.install_ibm_manager(agent, 'administrator')
        runner.execute_agent_on(agent, manifest)
      } # runs puppet agent on the dmgr machine with the websphere_class manifest
      let(:second_result) {
        WebSphereHelper.install_ibm_manager(agent, 'administrator')
        runner.execute_agent_on(agent, manifest)
      } # ditto

      it 'class should run successfully' do
        expect([0, 2]).to include(result.exit_code)
      end

      it 'class should be idempotent' do
        expect(second_result.exit_code).to eq 0
      end

      # make sure the target dir exists, that it was installed where we expect.
      it 'shall be installed to the instance directory' do
        rc = WebSphereHelper.remote_dir_exists(agent, WebSphereConstants.base_dir + '/' + WebSphereConstants.instance_name + '/AppServer')
        expect(rc).to eq 0
      end
    end
    context 'with non-root user' do
      let(:manifest) { WebSphereInstance.manifest(base_dir: '/home/webadmin') } # returns rendered spec/acceptance/fixtures/websphere_class.erb
      let(:runner) { BeakerAgentRunner.new }
      let(:result) {
        WebSphereHelper.install_ibm_manager(agent, 'nonadministrator')
        runner.execute_agent_on(agent, manifest)
      }# runs puppet agent on the dmgr machine with the websphere_class manifest
      let(:second_result) {
        WebSphereHelper.install_ibm_manager(agent, 'nonadministrator')
        runner.execute_agent_on(agent, manifest)
      } # ditto

      it 'class should run successfully' do
        expect([0, 2]).to include(result.exit_code)
      end

      it 'class should be idempotent' do
        expect(second_result.exit_code).to eq 0
      end

      # make sure the target dir exists, that it was installed where we expect.
      it 'shall be installed to the instance directory' do
        rc = WebSphereHelper.remote_dir_exists(agent, WebSphereConstants.base_dir + '/' + WebSphereConstants.instance_name + '/AppServer')
        expect(rc).to eq 0
      end
    end
  end
end
