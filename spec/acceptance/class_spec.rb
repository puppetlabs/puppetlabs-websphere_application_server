require 'spec_helper_acceptance'
require 'installer_constants'
require_relative './websphere_helper.rb'

describe 'verify setup of the nfs mount to install the webserver' do
  before(:all) do
    @template = 'websphere_setup_nfs.pp.tmpl'
    @config = { }
    @manifest = PuppetManifest.new(@template, @config)
    @result = @manifest.execute
  end
  it 'should run successfully' do
    expect(@result.exit_code).to eq 2
  end
end

describe 'user and group are setup' do
  before(:all) do
    @template = 'websphere_base.pp.tmpl'
    @config = {
      user: 'webadmin',
      group: 'webadmins',
    }
    @manifest = PuppetManifest.new(@template, @config)
    @result = @manifest.execute
  end

  it 'should run successfully' do
    expect(@result.exit_code).to eq 2
  end

  describe file($default_base_dir) do
    it { is_expected.to be_directory}
    it { is_expected.to be_owned_by 'webadmin' }
    it { is_expected.to be_grouped_into 'webadmins' }
  end
end

describe 'shall install a websphere app server instance' do
  before(:all) do
    @template = 'websphere_instance_install.pp.tmpl'
    @config = {
      user: WebSphereConstants.user,
      group: WebSphereConstants.group,
      base_dir: WebSphereConstants.base_dir,
      instance_name: WebSphereConstants.instance_name,
      instance_base: WebSphereConstants.instance_base,
      package_name: WebSphereConstants.package_name,
      package_version: WebSphereConstants.package_version,
      profile_base: WebSphereConstants.profile_base,
      was_installer: WebSphereConstants.was_installer,
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
