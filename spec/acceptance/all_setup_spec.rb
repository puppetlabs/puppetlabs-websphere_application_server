require 'spec_helper_acceptance'
require 'installer_constants'
require_relative './websphere_helper.rb'

describe 'setup the nfs mount and and setup the IBM installer' do
  before(:all) do
    @template = 'websphere_setup_nfs.pp.tmpl'
    @config = { }
    @manifest = PuppetManifest.new(@template, @config)
    @result = @manifest.execute
  end

  it 'should run successfully' do
    expect(@result.exit_code).to eq 2
  end

  describe file('/opt/QA_resources/ibm_websphere') do
    it { is_expected.to be_directory}
  end
end

describe 'setup the IBM installer' do
  before(:all) do
    @template = 'websphere_class.pp.tmpl'
    @config = {
      classname: 'ibm_installation_manager',
      optional: {
        group: 'system',
        source: '/opt/QA_resources/ibm_websphere/agent.installer.linux.gtk.x86_64_1.8.3000.20150606_0047.zip',
        target: '/opt/IBM/InstallationManager',
      },
      test: {
        deploy_source: true,
      }
    }
    @manifest = PuppetManifest.new(@template, @config)
    @result = @manifest.execute
  end

  it 'should run successfully' do
    expect(@result.exit_code).to eq 2
  end

  describe file('/opt/IBM/InstallationManager') do
    it { is_expected.to be_directory}
  end
end
