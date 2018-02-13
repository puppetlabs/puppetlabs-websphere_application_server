require 'spec_helper_acceptance'
require 'installer_constants'

describe 'install multiple instances' do
  before(:all) do
    @agent = WebSphereHelper.dmgr_host
    @second_instance_name = 'WebSphere86'
    @result = WebSphereInstance.install(@agent)
    @result = WebSphereInstance.install(@agent, _name = @second_instance_name)
    @second_result = WebSphereInstance.install(@agent, _name = @second_instance_name)
  end

  it 'runs successfully' do
    expect(@result.exit_code).to eq 2
  end

  it 'is idempotent' do
    expect(@second_result.exit_code).to eq 0
  end

  it 'shall be installed to the first instance directory' do
    rc = WebSphereHelper.remote_dir_exists(@agent, WebSphereConstants.base_dir + '/' + WebSphereConstants.instance_name + '/AppServer')
    expect(rc).to eq 0
  end

  it 'shall be installed to the second instance directory' do
    rc = WebSphereHelper.remote_dir_exists(@agent, WebSphereConstants.base_dir + '/' + @second_instance_name + '/AppServer')
    expect(rc).to eq 0
  end
end
