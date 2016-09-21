require 'beaker'
require 'beaker-rspec'
require 'beaker/puppet_install_helper'
require 'beaker/testmode_switcher/dsl'
require 'installer_constants'
require 'master_manipulator'

# automatically load any shared examples or contexts
Dir["./spec/support/**/*.rb"].sort.each { |f| require f }

def beaker_opts
  @env ||=
  {
    debug: true,
    trace: true,
    environment: { }
  }
end

def main

  RSpec.configure do |c|
    proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
    c.formatter = :documentation

    if ENV['BEAKER_TESTMODE'] == 'local'
      puts "Tests are running in local mode"
      return
    end

    if ENV["BEAKER_provision"] != "no"
      # Configure all nodes in nodeset
      nodes = WebSphereHelper.nodes
      install_pe_on(nodes, options)
      puppet_module_install(:source => proj_root, :module_name => 'websphere_application_server')
      nodes.each do |host|
        WebSphereHelper.mount_QA_resources(host)
        on host, puppet('module','install','puppet-archive')
        on host, puppet('module','install','puppetlabs-concat')
        on host, puppet('module','install', '--ignore-dependencies','puppetlabs-ibm_installation_manager')

        if host['platform'] =~ /^el/
          on(host, 'yum install -y lsof')
        elsif host['platform'] =~ /^ubuntu|^debian/
          on(host, 'apt-get install -y lsof')
        else
          fail("Acceptance tests cannot run as OS package [lsof] cannot be installed")
        end
        WebSphereHelper.install_ibm_manager(host)
      end
    end
  end
end

class BeakerAgentRunner
  include MasterManipulator::Site

  def execute_apply_on(host, manifest, opts = {})
    apply_manifest_on(
      host,
      manifest,
      expect_changes: true,
      debug: opts[:debug] || {},
      dry_run: opts[:dry_run] || {},
      environment: opts[:environment] || {},
      noop: opts[:noop] || {},
      trace: opts[:trace] || {},
      acceptable_exit_codes: (0...256)
    )
  end

  def execute_agent_on(host, manifest, opts = {})
    print "Manifest [#{manifest}]"
    environment_base_path = on(master, puppet('config', 'print', 'environmentpath')).stdout.rstrip
    prod_env_site_pp_path = File.join(environment_base_path, 'production', 'manifests', 'site.pp')
    site_pp = create_site_pp(master, manifest: manifest, node_def_name: host.hostname)
    site_pp_dir = File.dirname(prod_env_site_pp_path)
    create_remote_file(master, prod_env_site_pp_path, site_pp)
    set_perms_on_remote(master, site_pp_dir, '744', opts)

    cmd = ['agent', '--test', '--environment production']
    cmd << "--debug" if opts[:debug]
    cmd << "--noop" if opts[:noop]
    cmd << "--trace" if opts[:trace]

    # acceptable_exit_codes are passed because we want detailed-exit-codes but want to
    # make our own assertions about the responses
    on(host, # rubocop:disable Style/MultilineMethodCallBraceLayout
      puppet(*cmd),
      dry_run: opts[:dry_run],
      environment: opts[:environment] || {},
      acceptable_exit_codes: (0...256)
     )
    end
end

class WebSphereInstance
  def self.manifest(instance=WebSphereConstants.instance_name)
    instance_name = instance
    fixpack_name  = FixpackConstants.name
    instance_base = WebSphereConstants.base_dir + '/' + instance_name + '/AppServer'
    profile_base  = instance_base + '/profiles'
    java7_name    = instance_name + '_Java7'

    local_files_root_path = ENV['FILES'] || File.expand_path(File.join(File.dirname(__FILE__), 'acceptance/fixtures'))
    manifest_template     = File.join(local_files_root_path, 'websphere_class.erb')
    ERB.new(File.read(manifest_template)).result(binding)
  end

  def self.install(agent, instance=WebSphereConstants.instance_name)
    runner = BeakerAgentRunner.new
    runner.execute_agent_on(agent, WebSphereInstance.manifest(instance=instance))
  end
end

class WebSphereDmgr
  def self.manifest(agent)
    fail "agent param must be set to the beaker host of the dmgr agent" unless agent.hostname
    agent_hostname = agent.hostname

    local_files_root_path = ENV['FILES'] || File.expand_path(File.join(File.dirname(__FILE__), 'acceptance/fixtures'))
    manifest_template     = File.join(local_files_root_path, 'websphere_dmgr.erb')
    ERB.new(File.read(manifest_template)).result(binding)
  end

  def self.install(agent)
    runner = BeakerAgentRunner.new
    runner.execute_agent_on(agent, WebSphereInstance.manifest(agent))
  end
end

class WebSphereHelper
  def self.get_dmgr_host
    dmgr = NilClass
    hosts.each do |host|
      dmgr = host if host.host_hash[:roles].include?('dmgr')
    end
    dmgr
  end

  def self.get_ihs_host
    ihs = NilClass
    hosts.find{ |x| x.host_hash[:roles].include?('ihs') } ? ihs : NilClass
  end

  def self.get_app_host
    app = NilClass
    hosts.find{ |x| x.host_hash[:roles].include?('app') } ? app : NilClass
  end

  def self.is_master(host)
    host.host_hash[:roles].include?('master')
  end

  def self.is_agent(host)
    host.host_hash[:roles].include?('agent')
  end

  def self.get_ihs_server
    hosts.find{ |x| x.host_hash[:roles].include?('ihs') }
  end

  def self.get_fresh_node(node_name)
    system("curl -d --url vcloud.delivery.puppetlabs.net/vm/#{node_name} > create_node.txt")
    system("cat create_node.txt")
    File.readlines('create_node.txt').each do |line|
      if line =~/hostname/
        hostname = line.scan(/(:\s+")(.*)(")/)[0][1]
        return hostname
      end
    end
    system("rm -rf create_node.txt")
    raise 'Unable to get a fresh node created in the pooler [#{node_name}]'
  end

  def self.remote_group(host, group)
    on(host, "cat /etc/group",:acceptable_exit_codes => [0,1]).stdout.include?(group)
  end

  def self.make_remote_dir(host, directory)
    on(host, "test -d #{directory} || mkdir -p #{directory}",:acceptable_exit_codes => [0,1]).exit_code
  end

  def self.remote_dir_exists(host, directory)
    on(host, "test -d #{directory}",:acceptable_exit_codes => [0,1]).exit_code
  end

  def self.remote_file_exists(host, filepath)
    on(host, "test -f #{filepath}",:acceptable_exit_codes => [0,1]).exit_code
  end

  def self.load_oracle_jdbc_driver(host, source=HelperConstants.oracle_driver_source, target=HelperConstants.oracle_driver_target)
    Beaker::DSL::Helpers::HostHelpers::scp_to(host, source, target)
    fail("Failed to transfer the file [#{source}] to the remote") unless remote_file_exists(host, target)
  end

  def self.install_ibm_manager(host)
    ibm_install_pp = <<-MANIFEST
    class { 'ibm_installation_manager':
      deploy_source => true,
      source        => '/opt/QA_resources/ibm_installation_manager/1.8.3/agent.installer.linux.gtk.x86_64_1.8.3000.20150606_0047.zip',
      target        => '/opt/IBM/InstallationManager',
    }
    MANIFEST
    runner = BeakerAgentRunner.new
    result = runner.execute_agent_on(host, ibm_install_pp)
    fail("IBM manager failed to install on [#{host}]") unless result.exit_code.to_s =~ /[0,2]/
    fail("IBM manager install failed as IBM directories have failed to be created") unless self.remote_dir_exists(host, '/opt/IBM/InstallationManager')
  end

  def self.mount_QA_resources(host)
    make_remote_dir(host, HelperConstants.websphere_source_dir)
    nfs_pp = <<-MANIFEST
      file {"#{HelperConstants.qa_resources}":
        ensure => "directory",
      }

      if $::osfamily == 'Debian' {
        $pkg = "nfs-common"
      } else {
        # work_around for rhel bug https://bugzilla.redhat.com/show_bug.cgi?id=1325394
        package {'lvm2':
          ensure => latest,
          before => Package[$pkg],
        }

        $pkg = "nfs-utils"
      }

      package { $pkg: }

      mount { "#{HelperConstants.qa_resources}":
        device  => "#{HelperConstants.qa_resource_source}",
        fstype  => "nfs",
        ensure  => "mounted",
        options => "defaults",
        atboot  => true,
        require => Package[$pkg],
      }
    MANIFEST
    runner = BeakerAgentRunner.new
    result = runner.execute_agent_on(host, nfs_pp)

    fail("nfs mount of QA software failed [#{HelperConstants.qa_resource_source}]") unless result.exit_code.to_s =~ /[0,2]/
    fail("nfs mount failed as the software directories are missing") unless self.remote_dir_exists(host, WebSphereConstants.fixpack_installer)
  end

  def self.nodes
    nodes = []
    begin
      ENV['WEBSPHERE_NODES_REQUIRED'].split.each do |role|
        nodes.push(hosts.find{ |x| x.host_hash[:roles].include?(role) })
      end
    rescue
      Trace("The WEBSPHERE_NODES_REQUIRED env variable was set with roles that dont exist in your nodeset! Falling back to HOSTS!")
      nodes = hosts
    end
    nodes.compact
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

# execute main
main
