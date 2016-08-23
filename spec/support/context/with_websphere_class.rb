require 'installer_constants'
require 'spec_helper_acceptance'

shared_context 'with a websphere class' do
  before(:all) do
    instance_name = WebSphereConstants.instance_name
    fixpack_name  = FixpackConstants.name
    instance_base = WebSphereConstants.base_dir + '/' + instance_name + '/AppServer'
    profile_base  = instance_base + '/profiles'
    java7_name    = instance_name + '_Java7'

    master = WebSphereHelper.get_master

    local_files_root_path = ENV['FILES'] || File.expand_path(File.join(File.dirname(__FILE__), '../../acceptance/fixtures'))
    manifest_template     = File.join(local_files_root_path, 'websphere_class.erb')
    manifest             = ERB.new(File.read(manifest_template)).result(binding)

    @class_result = WebSphereHelper.agent_execute(manifest)

  end

  it 'class should run successfully' do
    expect(@class_result.exit_code).to eq 2
  end
end
