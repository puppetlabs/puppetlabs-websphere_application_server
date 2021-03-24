# frozen_string_literal: true

require 'puppet_litmus'
require 'installer_constants'
require 'singleton'
require 'tempfile'

def log_stdout(text)
  puts "#{'#' * 10} LOG START #{'#' * 10}\n"
  puts "#{text}\n"
  puts "#{'#' * 10} LOG END #{'#' * 10}\n\n"
end

def create_remote_file(name, full_name, file_content)
  include PuppetLitmus
  Tempfile.open name do |tempfile|
    File.open(tempfile.path, 'w') { |file| file.puts file_content }
    bolt_upload_file(tempfile.path, full_name)
  end
end

def fetch_agent_version(host)
  ENV['TARGET_HOST'] = host
  @puppet_agent_version ||= Helper.instance.run_shell('puppet --version').stdout.to_i
end

class Helper
  include PuppetLitmus
  include BoltSpec
  include Singleton
  def inventory_hash
    @inventory_hash ||= inventory_hash_from_inventory_file
  end

  def os
    platform = WebSphereHelper.platform_by_host(ENV['TARGET_HOST'])
    if platform.start_with?('win')
      { family: 'windows' }
    else
      { family: platform }
    end
  end

  def target_roles(roles)
    # rubocop:disable Style/MultilineBlockChain
    inventory_hash['groups'].map { |group|
      group['targets'].map { |node|
        { name: node['uri'], role: node['vars']['role'] } if node['vars']['role'].include? roles
      }.reject { |val| val.nil? }
    }.flatten
    # rubocop:enable Style/MultilineBlockChain
  end
end

class LitmusAgentRunner
  include PuppetLitmus

  def create_site_pp_host(server_host, opts = {})
    opts[:manifest] ||= ''
    opts[:node_def_name] ||= 'default'
    ENV['TARGET_HOST'] = server_host
    server_certname = Helper.instance.run_shell('puppet config print certname').stdout.rstrip

    default_def = <<-MANIFEST
node default {
}
MANIFEST

    node_def = <<-MANIFEST
node #{opts[:node_def_name]} {
#{opts[:manifest]}
}
MANIFEST

    if opts[:node_def_name] != 'default'
      node_def = "#{default_def}\n#{node_def}"
    end

    site_pp = <<-MANIFEST
filebucket { 'main':
server => '#{server_certname}',
path   => false,
}

File { backup => 'main' }

#{node_def}
MANIFEST

    site_pp
  end

  def generate_site_pp(agents_hash)
    server = WebSphereHelper.host_by_role('server')
    # Initialize a blank site.pp
    site_pp = create_site_pp_host(server.first, manifest: '')
    agents_hash.each do |agent, manifest|
      # pull out the node specific block for the site.pp
      ENV['TARGET_HOST'] = agent
      agent_fqdn = Helper.instance.run_shell('facter fqdn').stdout.delete("\n")
      node_block = create_site_pp_host(server.first, manifest: manifest, node_def_name: agent_fqdn)
      node_block = node_block.split("node #{agent_fqdn}")[-1]
      node_block = "node '#{agent_fqdn}'#{node_block}"
      site_pp += node_block
    end
    site_pp
  end

  def copy_site_pp(site_pp, _opts = {})
    server = WebSphereHelper.host_by_role('server')
    ENV['TARGET_HOST'] = server.first
    environment_base_path = run_shell('puppet config print environmentpath').stdout.rstrip
    prod_env_site_pp_path = File.join(environment_base_path, 'production', 'manifests', 'site.pp')
    site_pp_dir = File.dirname(prod_env_site_pp_path)
    site_pp_file = File.new('site.pp', 'w')
    site_pp_file.write(site_pp)
    site_pp_file.close
    bolt_upload_file('site.pp', prod_env_site_pp_path)
    run_shell("chmod 0744 #{site_pp_dir}")
    run_shell("chmod 0744 #{prod_env_site_pp_path}")
    run_shell("chown -R puppet:puppet #{site_pp_dir}")
    run_shell("chown -R puppet:puppet #{prod_env_site_pp_path}")
    print "site.pp:\n#{site_pp}"
  end

  def execute_agent_on(host, manifest = nil, opts = {})
    if manifest
      site_pp = generate_site_pp(host => manifest)
      copy_site_pp(site_pp, opts)
    end
    cmd =  'agent --test --environment production'
    cmd += ' --debug' if opts[:debug]
    cmd += ' --noop' if opts[:noop]
    cmd += ' --trace' if opts[:trace]
    # acceptable_exit_codes are passed because we want detailed-exit-codes but want to
    # make our own assertions about the responses
    ENV['TARGET_HOST'] = host
    run_shell("puppet #{cmd} #{opts[:dry_run]} #{opts[:environment]}", expect_failures: true)
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
    runner = LitmusAgentRunner.new
    stdout = runner.execute_agent_on(agent, manifest(instance: instance))
    log_stdout(stdout.stdout) unless [0, 2].include?(stdout.exit_code)
    stdout
  end
end

class WebSphereDmgr
  def self.manifest(target_agent:,
                    instance: WebSphereConstants.instance_name,
                    base_dir: WebSphereConstants.base_dir,
                    user: WebSphereConstants.user,
                    group: WebSphereConstants.group)
    raise 'agent param must be set to the dmgr agent' unless target_agent
    ENV['TARGET_HOST'] = target_agent
    agent_hostname = Helper.instance.run_shell('facter fqdn').stdout.delete("\n")
    instance_name = instance
    instance_base = base_dir + '/' + instance_name + '/AppServer'
    profile_base  = instance_base + '/profiles'

    local_files_root_path = ENV['FILES'] || File.expand_path(File.join(File.dirname(__FILE__), 'acceptance/fixtures'))
    manifest_template     = File.join(local_files_root_path, 'websphere_dmgr.erb')
    ERB.new(File.read(manifest_template)).result(binding)
  end

  def self.install(agent)
    runner = LitmusAgentRunner.new
    stdout = runner.execute_agent_on(agent, manifest(target_agent: agent))
    log_stdout(stdout.stdout) unless [0, 2].include?(stdout.exit_code)
    stdout
  end
end

class WebSphereIhs
  def self.manifest(target_agent:,
                    listen_port:,
                    status: 'running',
                    user: WebSphereConstants.user,
                    group: WebSphereConstants.group,
                    base_dir: WebSphereConstants.base_dir)
    raise 'agent param must be set to the ihs agent' unless target_agent
    agent_hostname = target_agent
    ihs_status = status
    local_files_root_path = ENV['FILES'] || File.expand_path(File.join(File.dirname(__FILE__), 'acceptance/fixtures'))
    manifest_template     = File.join(local_files_root_path, 'websphere_ihs.erb')
    ERB.new(File.read(manifest_template)).result(binding)
  end

  def self.install(agent)
    runner = LitmusAgentRunner.new
    stdout = runner.execute_agent_on(agent, manifest(target_agent: agent))
    log_stdout(stdout.stdout) unless [0, 2].include?(stdout.exit_code)
    stdout
  end
end

class WebSphereAppServer
  include PuppetLitmus
  def self.manifest(agent, dmgr_agent)
    raise 'agent param must be set to the dmgr agent' unless agent
    ENV['TARGET_HOST'] = agent
    agent_hostname = Helper.instance.run_shell('facter fqdn').stdout.delete("\n")
    ENV['TARGET_HOST'] = dmgr_agent
    dmgr_hostname = Helper.instance.run_shell('facter fqdn').stdout.delete("\n")

    local_files_root_path = ENV['FILES'] || File.expand_path(File.join(File.dirname(__FILE__), 'acceptance/fixtures'))
    manifest_template     = File.join(local_files_root_path, 'websphere_appserver.erb')
    ERB.new(File.read(manifest_template)).result(binding)
  end

  def self.install(agent)
    runner = LitmusAgentRunner.new
    stdout = runner.execute_agent_on(agent, WebSphereDmgr.manifest(agent))
    log_stdout(stdout.stdout) unless [0, 2].include?(stdout.exit_code)
    stdout
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
    array_nodes = []
    inventory_hash = Helper.instance.inventory_hash_from_inventory_file
    inventory_hash['groups'].each do |group|
      group['targets'].each do |node|
        if node['vars']['role'] == role
          array_nodes.push(node['uri'])
        end
      end
    end
    array_nodes
  end

  def self.all_hosts
    array_nodes = []
    inventory_hash = Helper.instance.inventory_hash_from_inventory_file
    inventory_hash['groups'].each do |group|
      group['targets'].each do |node|
        array_nodes.push(node['uri'])
      end
    end
    array_nodes
  end

  def self.dmgr_host
    hosts = host_by_role('dmgr')
    hosts.first
  end

  def self.ihs_host
    hosts = host_by_role('ihs')
    hosts.first
  end

  def self.app_host
    hosts = host_by_role('appserver')
    hosts.first
  end

  def self.ihs_server
    hosts = host_by_role('ihs')
    hosts.first
  end

  def self.platform_by_host(host)
    array_nodes = []
    inventory_hash = Helper.instance.inventory_hash_from_inventory_file
    inventory_hash['groups'].each do |group|
      group['targets'].each do |node|
        if node['uri'] == host
          array_nodes.push(node['facts']['platform'])
        end
      end
    end
    array_nodes.first
  end

  def self.remote_group(host, group)
    ENV['TARGET_HOST'] = host
    Helper.instance.run_shell('cat /etc/group').stdout.include?(group)
  end

  def self.make_remote_dir(host, directory)
    ENV['TARGET_HOST'] = host
    Helper.instance.run_shell("test -d #{directory} || mkdir -p #{directory}")
  end

  def self.remote_dir_exists(host, directory)
    ENV['TARGET_HOST'] = host
    Helper.instance.run_shell("test -d #{directory}")
  end

  def self.remote_file_exists(host, filepath)
    ENV['TARGET_HOST'] = host
    Helper.instance.run_shell("test -f #{filepath}")
  end

  def self.install_ibm_manager(host: install_host,
                               user: WebSphereConstants.user,
                               group: WebSphereConstants.group,
                               imode: WebSphereConstants.installation_mode,
                               user_home: WebSphereConstants.user_home)
    source = if ENV['CLOUD_CI']
               "#{HelperConstants.qa_resources}/ibm_websphere/agent.installer.linux.gtk.x86_64_1.8.7000.20170706_2137.zip"
             else
               "#{HelperConstants.qa_resources}/ibm_installation_manager/1.8.7/agent.installer.linux.gtk.x86_64_1.8.7000.20170706_2137.zip"
             end
    ibm_install_pp = if imode == 'nonadministrator'
                       <<-MANIFEST
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
                           source            => '#{source}',
                           installation_mode => '#{imode}',
                           user              => '#{user}',
                           group             => '#{group}',
                           user_home         => '#{user_home}',
                         }
                       MANIFEST
                     elsif imode == 'administrator'
                       <<-MANIFEST
                         class { 'ibm_installation_manager':
                           deploy_source     => true,
                           source            => '#{source}',
                           installation_mode => 'administrator',
                         }
                       MANIFEST
                     end
    runner = LitmusAgentRunner.new
    stdout = runner.execute_agent_on(host, ibm_install_pp)
    log_stdout(stdout.stdout) unless [0, 2].include?(stdout.exit_code)
    stdout
  end

  def self.mount_qa_resources(host)
    ENV['TARGET_HOST'] = host
    make_remote_dir(host, HelperConstants.websphere_source_dir)
    nfs_pp = <<-MANIFEST
      file {"#{HelperConstants.qa_resources}":
        ensure => "directory",
      }

      if $::osfamily == 'Debian' {
        $pkg = 'nfs-common'
      } else {
        # work_around for rhel bug https://bugzilla.redhat.com/show_bug.cgi?id=1325394
        $pkg = 'nfs-utils'
        package {'lvm2':
          ensure => latest,
          before => Package[$pkg],
        }
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
    runner = LitmusAgentRunner.new
    result = runner.execute_agent_on(host, nfs_pp)

    raise("nfs mount of QA software failed [#{HelperConstants.qa_resource_source}]") unless %r{[0,2]}.match?(result.exit_code.to_s)
    raise('nfs mount failed as the software directories are missing') unless remote_dir_exists(host, WebSphereConstants.fixpack_installer)
  end
end

# automatically load any shared examples or contexts
Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

RSpec.configure do |c|
  c.formatter = :documentation
  if c.filter.rules.key? :integration
    warn('>>> A valid inventory.yaml was not found. <<<') if Helper.instance.target_roles('server').empty?
  else
    c.filter_run_excluding :integration
  end

  # set on the server
  ENV['TARGET_HOST'] = WebSphereHelper.host_by_role('server').first
  Helper.instance.run_shell('puppet module install puppet-archive')
  Helper.instance.run_shell('puppet module install puppetlabs-concat')
  Helper.instance.run_shell('puppet module install puppetlabs-ibm_installation_manager --ignore-dependencies')

  # workaround to avoid string_frozen_literal on ibm_installation_manager
  ibm_installation_manager_path = '/etc/puppetlabs/code/environments/production/modules/ibm_installation_manager'
  ibm_installation_manager_metadata = JSON.parse(Helper.instance.run_shell("cat #{ibm_installation_manager_path}/metadata.json").stdout)
  if ibm_installation_manager_metadata['version'] == '3.0.0'
    Helper.instance.run_shell("sed -i 's/cmd_options <</cmd_options +=/g' #{ibm_installation_manager_path}/lib/puppet/provider/ibm_pkg/imcl.rb")
  end

  # install puppetdb
  Helper.instance.run_shell('puppet module install puppetlabs-inifile')
  Helper.instance.run_shell('puppet module install puppetlabs-postgresql')
  Helper.instance.run_shell('puppet module install puppetlabs-firewall')
  Helper.instance.run_shell('puppet module install puppetlabs-puppetdb --ignore-dependencies')
  install_puppetdb_pp = <<-PP
    class { 'puppetdb': }
    class { 'puppetdb::master::config': }
  PP
  Helper.instance.apply_manifest(install_puppetdb_pp)
  Helper.instance.run_shell('iptables -F')
  Helper.instance.run_shell('systemctl restart puppetserver')
  Helper.instance.run_shell('puppet config set storeconfigs true')
  puppetdb_conf = <<-EOS
[main]
server_urls = https://#{Helper.instance.run_shell('facter fqdn').stdout.delete("\n")}:8081/
soft_write_failure = false
EOS
  routes_yaml = <<-YAML
---
apply:
  catalog:
    terminus: compiler
    cache: puppetdb
  resource:
    terminus: ral
    cache: puppetdb
  facts:
    terminus: facter
    cache: puppetdb_apply
YAML

  ['appserver', 'dmgr', 'ihs'].each do |machine|
    ENV['TARGET_HOST'] = WebSphereHelper.host_by_role(machine).first
    Helper.instance.run_shell('puppet resource package puppetdb-termini ensure=latest')
    if Helper.instance.run_shell('puppet --version').stdout.to_i == 7
      # Helper.instance.run_shell('puppet config set storeconfigs true')
      create_remote_file('puppetdb_conf', '/etc/puppetlabs/puppet/puppetdb.conf', puppetdb_conf)
      create_remote_file('routes_yaml', '/etc/puppetlabs/puppet/routes.yaml', routes_yaml)
      Helper.instance.run_shell('chmod +r /etc/puppetlabs/puppet/puppetdb.conf')
      Helper.instance.run_shell('chmod +r /etc/puppetlabs/puppet/routes.yaml')
    end
    WebSphereHelper.mount_qa_resources(WebSphereHelper.host_by_role(machine).first) unless ENV['CLOUD_CI']
    lsof_pp = <<-PP
      package { 'lsof': ensure => present, }
    PP
    Helper.instance.apply_manifest(lsof_pp)
    WebSphereHelper.install_ibm_manager(host: WebSphereHelper.host_by_role(machine).first)
    WebSphereHelper.install_ibm_manager(host: WebSphereHelper.host_by_role(machine).first,
                                        imode: 'nonadministrator',
                                        user_home: '/home/webadmin')
  end
end
