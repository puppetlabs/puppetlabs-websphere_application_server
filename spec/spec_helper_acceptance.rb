require 'beaker'
require 'beaker-rspec'
require 'beaker/testmode_switcher/dsl'
require 'mustache'
require 'installer_constants'

def remote_group(host, group)
  on(host, "cat /etc/group").stdout.include?(group)
end

def make_remote_dir(host, directory)
  on(host, "test -d #{directory} || mkdir -p #{directory}")
end

def remote_file_exists(host, filepath)
  on(host, "test -f #{filepath}")
end

def configure_master
  hosts.find{ |x| x.host_hash[:roles].include?('master') } ? master : fail("No master node detected by role!")
  make_remote_dir(master, HelperConstants.websphere_source_dir)
  
  unless remote_group(master, "system")
    on(master, "groupadd system")
  end
  on(master, "yum install -y nfs-utils")
end

RSpec.configure do |c|
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
  c.formatter = :documentation

  if ENV['BEAKER_TESTMODE'] == 'local'
    puts "Tests are runing in local mode"
    return
  end

  if ENV["BEAKER_provision"] == "yes" ||  ENV["BEAKER_reload_dev_module"] == "yes"
    c.before :suite do
      puppet_module_install(:source => proj_root, :module_name => 'websphere_application_server')
    end
  end

  unless ENV["BEAKER_provision"] == "no"
    # Configure all nodes in nodeset
    configure_master
    install_pe
    hosts.each do |host|
      on host, puppet('module','install','puppet-archive')
      on host, puppet('module','install','puppetlabs-stdlib')
      on host, puppet('module','install','puppetlabs-concat')
      on host, puppet('module','install','puppetlabs-ibm_installation_manager')
    end
  end
end


class PuppetManifest < Mustache
  def initialize(file, config) # rubocop:disable Metrics/AbcSize
    @template_file = File.join(Dir.getwd, 'spec', 'acceptance', 'fixtures', file)

    # decouple the config we're munging from the value used in the tests
    config = Marshal.load( Marshal.dump(config) )
    config.each do |key, value|
      config_value = self.class.to_generalized_data(value)
      instance_variable_set("@#{key}".to_sym, config_value)
      self.class.send(:attr_accessor, key)
    end
  end

  def execute
    Beaker::TestmodeSwitcher::DSL.execute_manifest(self.render, beaker_opts)
  end

  def self.to_generalized_data(val)
    case val
    when Hash
      to_generalized_hash_list(val)
    when Array
      to_generalized_array_list(val)
    else
      val
    end
  end

  # returns an array of :k =>, :v => hashes given a Hash
  # { :a => 'b', :c => 'd' } -> [{:k => 'a', :v => 'b'}, {:k => 'c', :v => 'd'}]
  def self.to_generalized_hash_list(hash)
    hash.map { |k, v| { :k => k, :v => v }}
  end

  # necessary to build like [{ :values => Array }] rather than [[]] when there
  # are nested hashes, for the sake of Mustache being able to render
  # otherwise, simply return the item
  def self.to_generalized_array_list(arr)
    arr.map do |item|
      if item.class == Hash
        {
          :values => to_generalized_hash_list(item)
        }
      else
        item
      end
    end
  end

  def self.env_id
    @env_id ||= (
      ENV['BUILD_DISPLAY_NAME'] ||
      (ENV['USER'] + '@' + Socket.gethostname.split('.')[0])
    ).delete("'")
  end

  def self.rds_id
    @rds_id ||= (
      ENV['BUILD_DISPLAY_NAME'] ||
      (ENV['USER'])
    ).gsub(/\W+/, '')
  end

  def self.env_dns_id
    @env_dns_id ||= @env_id.gsub(/[^\\dA-Za-z-]/, '')
  end
end

def beaker_opts
  @env ||=
  {
    debug: true,
    trace: true,
    environment: { }
  }
end
