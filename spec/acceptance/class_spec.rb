require 'spec_helper_acceptance'
require 'installer_constants'
require_relative './websphere_helper.rb'

describe 'user and group are setup' do
  before(:all) do
    @template = 'websphere_class.pp.tmpl'
    @config = {
      classname: 'websphere_application_server',
      optional: {
        user: WebSphereConstants.user,
        group: WebSphereConstants.group,
        base_dir: WebSphereConstants.base_dir,
      }
    }
    @manifest = PuppetManifest.new(@template, @config)
    @result = @manifest.execute
  end

  it 'should run successfully' do
    expect(@result.exit_code).to eq 2
  end

  describe file($default_base_dir) do
    it { is_expected.to be_directory}
    it { is_expected.to be_owned_by WebSphereConstants.user }
    it { is_expected.to be_grouped_into WebSphereConstants.group }
  end
end
