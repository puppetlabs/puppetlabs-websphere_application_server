require 'beaker-rspec'
require 'beaker/puppet_install_helper'
require 'beaker/testmode_switcher/dsl'
require 'mustache'

def timestamp
  Time.now.strftime('%Y-%m-%d-%H:%M:%S.%L')
end

PUPPET_INSTALL_TYPE = ENV['PUPPET_INSTALL_TYPE'] || 'pe'
puts "Installing [#{PUPPET_INSTALL_TYPE}] put install type here ... #{timestamp}"
run_puppet_install_helper unless ENV["BEAKER_provision"] == "no"
puts "Installation complete ... #{timestamp}"

UNSUPPORTED_PLATFORMS = ['Suse','windows','AIX','Solaris']

RSpec.configure do |c|
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  c.formatter = :documentation

  if ENV['BEAKER_TESTMODE'] == 'local'
    puts "Tests are runing in local mode"
    return
  end

  unless ENV["BEAKER_provision"] == "no"
    # Configure all nodes in nodeset
    c.before :suite do
      puppet_module_install(:source => proj_root, :module_name => 'websphere_application_server')
    end
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
