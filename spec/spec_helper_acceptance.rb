require 'beaker'
require 'beaker-rspec'
require 'beaker/puppet_install_helper'
require 'beaker/testmode_switcher/dsl'
require 'installer_constants'
require 'master_manipulator'

# automatically load any shared examples or contexts
Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

def beaker_opts
  @env ||=
    {
      debug: true,
      trace: true,
      environment: {},
    }
end

class String
  # Provide ability to remove indentation from strings, for the purpose of
  # left justifying heredoc blocks.
  def unindent
    gsub(%r{^#{scan(%r{^\s*}).min_by { |l| l.length }}}, '')
  end
end

def main
  RSpec.configure do |c|
    proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
    c.formatter = :documentation

    if ENV['BEAKER_TESTMODE'] == 'local'
      puts 'Tests are running in local mode'
      break
    end

    if ENV['BEAKER_provision'] != 'no'
      # Configure all nodes in nodeset
      install_pe_on(hosts, options)
      puppet_module_install(source: proj_root, module_name: 'websphere_application_server')
      hosts.each do |host|
        WebSphereHelper.mount_qa_resources(host)
        on host, puppet('module', 'install', 'puppet-archive')
        on host, puppet('module', 'install', 'puppetlabs-concat')
        on host, puppet('module', 'install', '--ignore-dependencies', 'puppetlabs-ibm_installation_manager')

        if host['platform'] =~ %r{^el}
          on(host, 'yum install -y lsof')
        elsif host['platform'] =~ %r{^ubuntu|^debian}
          on(host, 'apt-get install -y lsof')
        else
          raise('Acceptance tests cannot run as OS package [lsof] cannot be installed')
        end
        WebSphereHelper.install_ibm_manager(host: host)
        WebSphereHelper.install_ibm_manager(host: host,
                                            imode: 'nonadministrator',
                                            user_home: '/home/webadmin')
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
      acceptable_exit_codes: (0...256),
    )
  end

  def generate_site_pp(agents_hash)
    # Initialize a blank site.pp
    site_pp = create_site_pp(master, manifest: '')
    agents_hash.each do |agent, manifest|
      # pull out the node specific block for the site.pp
      node_block = create_site_pp(master, manifest: manifest, node_def_name: agent.hostname)
      node_block = node_block.split("node #{agent.hostname}")[-1]
      node_block = "node #{agent.hostname}#{node_block}"
      site_pp << node_block
    end
    site_pp
  end

  def copy_site_pp(site_pp, opts = {})
    environment_base_path = on(master, puppet('config', 'print', 'environmentpath')).stdout.rstrip
    prod_env_site_pp_path = File.join(environment_base_path, 'production', 'manifests', 'site.pp')
    site_pp_dir = File.dirname(prod_env_site_pp_path)
    create_remote_file(master, prod_env_site_pp_path, site_pp)
    set_perms_on_remote(master, site_pp_dir, '744', opts)
    print "site.pp:\n#{site_pp}"
  end

  def execute_agent_on(host, manifest = nil, opts = {})
    if manifest
      site_pp = generate_site_pp(host => manifest)
      copy_site_pp(site_pp, opts)
    end

    cmd = ['agent', '--test', '--environment production']
    cmd << '--debug' if opts[:debug]
    cmd << '--noop' if opts[:noop]
    cmd << '--trace' if opts[:trace]

    # acceptable_exit_codes are passed because we want detailed-exit-codes but want to
    # make our own assertions about the responses
    on(host,
       puppet(*cmd),
       dry_run: opts[:dry_run],
       environment: opts[:environment] || {},
       acceptable_exit_codes: (0...256))
  end
end

class WebSphereInstance
  def self.manifest(instance: WebSphereConstants.instance_name,
                    base_dir: WebSphereConstants.base_dir,
                    user: WebSphereConstants.user,
                    group: WebSphereConstants.group)
    instance_name = instance
    fixpack_name  = FixpackConstants.name
    instance_base = base_dir + '/' + instance_name + '/AppServer'
    profile_base  = instance_base + '/profiles'
    java7_name    = instance_name + '_Java7'

    local_files_root_path = ENV['FILES'] || File.expand_path(File.join(File.dirname(__FILE__), 'acceptance/fixtures'))
    manifest_template     = File.join(local_files_root_path, 'websphere_class.erb')
    ERB.new(File.read(manifest_template)).result(binding)
  end

  def self.install(agent, instance = WebSphereConstants.instance_name)
    runner = BeakerAgentRunner.new
    runner.execute_agent_on(agent, manifest(instance: instance))
  end
end

class WebSphereDmgr
  def self.manifest(target_agent:,
                    instance: WebSphereConstants.instance_name,
                    base_dir: WebSphereConstants.base_dir,
                    user: WebSphereConstants.user,
                    group: WebSphereConstants.group)
    raise 'agent param must be set to the beaker host of the dmgr agent' unless target_agent.hostname
    agent_hostname = target_agent.hostname
    instance_name = instance
    instance_base = base_dir + '/' + instance_name + '/AppServer'
    profile_base  = instance_base + '/profiles'

    local_files_root_path = ENV['FILES'] || File.expand_path(File.join(File.dirname(__FILE__), 'acceptance/fixtures'))
    manifest_template     = File.join(local_files_root_path, 'websphere_dmgr.erb')
    ERB.new(File.read(manifest_template)).result(binding)
  end

  def self.install(agent)
    runner = BeakerAgentRunner.new
    runner.execute_agent_on(agent, manifest(target_agent: agent))
  end
end

class WebSphereIhs
  def self.manifest(target_agent:,
                    listen_port:,
                    status: 'running',
                    user: WebSphereConstants.user,
                    group: WebSphereConstants.group,
                    base_dir: WebSphereConstants.base_dir)
    raise 'agent param must be set to the beaker host of the ihs agent' unless target_agent.hostname
    agent_hostname = target_agent.hostname
    ihs_status = status
    local_files_root_path = ENV['FILES'] || File.expand_path(File.join(File.dirname(__FILE__), 'acceptance/fixtures'))
    manifest_template     = File.join(local_files_root_path, 'websphere_ihs.erb')
    ERB.new(File.read(manifest_template)).result(binding)
  end

  def self.install(agent)
    runner = BeakerAgentRunner.new
    runner.execute_agent_on(agent, manifest(target_agent: agent))
  end
end

class WebSphereAppServer
  def self.manifest(agent, dmgr_agent)
    raise 'agent param must be set to the beaker host of the dmgr agent' unless agent.hostname
    agent_hostname = agent.hostname
    dmgr_hostname = dmgr_agent.hostname

    local_files_root_path = ENV['FILES'] || File.expand_path(File.join(File.dirname(__FILE__), 'acceptance/fixtures'))
    manifest_template     = File.join(local_files_root_path, 'websphere_appserver.erb')
    ERB.new(File.read(manifest_template)).result(binding)
  end

  def self.install(agent)
    runner = BeakerAgentRunner.new
    runner.execute_agent_on(agent, WebSphereDmgr.manifest(agent))
  end
end

class WebSphereHelper
  def self.stop_server(server_name: sname,
                       user: usr,
                       profile_base: pb,
                       profile_name: pn)

    local_files_root_path = ENV['FILES'] || File.expand_path(File.join(File.dirname(__FILE__), 'acceptance/fixtures'))
    manifest_template     = File.join(local_files_root_path, 'websphere_stop_server.erb')
    ERB.new(File.read(manifest_template), nil, '-').result(binding)
  end

  def self.host_by_role(role)
    dmgr = NilClass
    hosts.each do |host|
      dmgr = host if host.host_hash[:roles].include?(role)
    end
    dmgr
  end

  def self.dmgr_host
    host_by_role('dmgr')
  end

  def self.ihs_host
    host_by_role('ihs')
  end

  def self.app_host
    host_by_role('appserver')
  end

  def self.is_master(host)
    host.host_hash[:roles].include?('master')
  end

  def self.is_agent(host)
    host.host_hash[:roles].include?('agent')
  end

  def self.ihs_server
    hosts.find { |x| x.host_hash[:roles].include?('ihs') }
  end

  def self.fresh_node(node_name)
    system("curl -d --url vcloud.delivery.puppetlabs.net/vm/#{node_name} > create_node.txt")
    system('cat create_node.txt')
    File.readlines('create_node.txt').each do |line|
      if line =~ %r{hostname}
        hostname = line.scan(%r{(:\s+")(.*)(")})[0][1]
        return hostname
      end
    end
    system('rm -rf create_node.txt')
    raise 'Unable to get a fresh node created in the pooler [#{node_name}]'
  end

  def self.remote_group(host, group)
    on(host, 'cat /etc/group', acceptable_exit_codes: [0, 1]).stdout.include?(group)
  end

  def self.make_remote_dir(host, directory)
    on(host, "test -d #{directory} || mkdir -p #{directory}", acceptable_exit_codes: [0, 1]).exit_code
  end

  def self.remote_dir_exists(host, directory)
    on(host, "test -d #{directory}", acceptable_exit_codes: [0, 1]).exit_code
  end

  def self.remote_file_exists(host, filepath)
    on(host, "test -f #{filepath}", acceptable_exit_codes: [0, 1]).exit_code
  end

  def self.load_oracle_jdbc_driver(host, source = HelperConstants.oracle_driver_source, target = HelperConstants.oracle_driver_target)
    Beaker::DSL::Helpers::HostHelpers.scp_to(host, source, target)
    raise("Failed to transfer the file [#{source}] to the remote") unless remote_file_exists(host, target)
  end

  def self.install_ibm_manager(host: install_host,
                               user: WebSphereConstants.user,
                               group: WebSphereConstants.group,
                               imode: WebSphereConstants.installation_mode,
                               user_home: WebSphereConstants.user_home)
    ibm_install_pp = if imode == 'nonadministrator'
                       <<-MANIFEST.unindent
                         group { '#{group}':
                           ensure => present,
                         }

                         user { '#{user}':
                           managehome => true,
                           home       => '#{user_home}',
                           gid        => '#{group}',
                         }

                         class { 'ibm_installation_manager':
                           deploy_source     => true,
                           source            => '/opt/QA_resources/ibm_installation_manager/1.8.3/agent.installer.linux.gtk.x86_64_1.8.3000.20150606_0047.zip',
                           installation_mode => '#{imode}',
                           user              => '#{user}',
                           group             => '#{group}',
                           user_home         => '#{user_home}',
                         }
                       MANIFEST
                     elsif imode == 'administrator'
                       <<-MANIFEST.unindent
                         class { 'ibm_installation_manager':
                           deploy_source     => true,
                           source            => '/opt/QA_resources/ibm_installation_manager/1.8.3/agent.installer.linux.gtk.x86_64_1.8.3000.20150606_0047.zip',
                           installation_mode => 'administrator',
                         }
                       MANIFEST
                     end
    runner = BeakerAgentRunner.new
    result = runner.execute_agent_on(host, ibm_install_pp)
    raise("IBM manager failed to install on [#{host}]") unless result.exit_code.to_s =~ %r{[0,2]}
    raise('IBM manager install failed as IBM directories have failed to be created') unless remote_dir_exists(host, '/home/webadmin/IBM/InstallationManager')
  end

  def self.mount_qa_resources(host)
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

    raise("nfs mount of QA software failed [#{HelperConstants.qa_resource_source}]") unless result.exit_code.to_s =~ %r{[0,2]}
    raise('nfs mount failed as the software directories are missing') unless remote_dir_exists(host, WebSphereConstants.fixpack_installer)
  end
end

# execute main
main
