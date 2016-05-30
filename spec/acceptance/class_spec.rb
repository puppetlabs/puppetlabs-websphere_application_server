require 'spec_helper_acceptance'
require_relative './websphere_helper.rb'

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
    expect(@result.exit_code).to eq 0
  end

  describe file($default_base_dir) do
    it { is_expected.to be_directory}
    it { is_expected.to be_owned_by 'webadmin' }
    it { is_expected.to be_grouped_into 'webadmins' }
  end

end

describe 'should be installed at base_dir' do
  before(:all) do
    @template = 'websphere_file.pp.tmpl'
    @config = {
      base_dir: '/opt/myIBM',
      require_file: "File['/opt/myIBM']",
    }
    @manifest = PuppetManifest.new(@template, @config)
    @result = @manifest.execute
  end

  it 'should run successfully' do
    expect(@result.exit_code).to eq 0
  end

  describe file($default_base_dir) do
    it { is_expected.to be_directory}
    it { is_expected.to be_owned_by 'webadmin' }
    it { is_expected.to be_grouped_into 'webadmins' }
  end

  describe file('/etc/puppetlabs/facter/facts.d/websphere.yaml') do
    it { is_expected.to be_file }
    it { is_expected.to contain %r{websphere_base_dir: /opt/myIBM} }
  end
end
