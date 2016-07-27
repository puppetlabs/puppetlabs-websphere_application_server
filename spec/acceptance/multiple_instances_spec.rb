require 'spec_helper_acceptance'
require 'installer_constants'
require 'master_manipulator'

describe 'install multiple instances' do
  include_context "with a websphere class"

  before(:all) do
    instance_name = 'WebSphere86'
    fixpack_name  = 'WebSphere_8654_fixpack'
    instance_base = WebSphereConstants.base_dir + '/' + instance_name + '/AppServer'
    profile_base  = instance_base + '/profiles'
    java7_name    = instance_name + '_Java7'

    master = WebSphereHelper.get_master

    local_files_root_path = ENV['FILES'] || File.expand_path(File.join(File.dirname(__FILE__), './fixtures'))
    manifest_template     = File.join(local_files_root_path, 'websphere_class.erb')
    @manifest             = ERB.new(File.read(manifest_template)).result(binding)

    @result = WebSphereHelper.agent_execute(@manifest)
  end

  it 'should run successfully' do
    expect(@result.exit_code).to eq 2
  end
end
