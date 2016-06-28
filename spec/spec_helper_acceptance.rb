require 'beaker'
require 'beaker-rspec'
require 'beaker/puppet_install_helper'
require 'beaker/testmode_switcher/dsl'
require 'installer_constants'

# automatically load any shared examples or contexts
Dir["./spec/support/**/*.rb"].sort.each { |f| require f }

def main

  run_puppet_install_helper

  RSpec.configure do |c|
    proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
    c.formatter = :documentation

    if ENV['BEAKER_TESTMODE'] == 'local'
      puts "Tests are running in local mode"
      return
    end

    if ENV["BEAKER_provision"] != "no"
      # Configure all nodes in nodeset
      WebSphereHelper.configure_master
      puppet_module_install(:source => proj_root, :module_name => 'websphere_application_server')

      hosts.each do |host|
        WebSphereHelper.mount_QA_resources
        on host, puppet('module','install','puppet-archive')
        on host, puppet('module','install','puppetlabs-concat')
        on host, puppet('module','install','puppetlabs-ibm_installation_manager')
        WebSphereHelper.install_ibm_manager(host) if host.host_hash[:roles].include?('master')
      end
    end
  end
end

class WebSphereHelper
  def self.get_master
    hosts.find{ |x| x.host_hash[:roles].include?('master') } ? master : Nil
  end

  def self.agent_execute(manifest)
    Beaker::TestmodeSwitcher::DSL.execute_manifest(manifest, beaker_opts)
  end

  def self.remote_group(host, group)
    on(host, "cat /etc/group").stdout.include?(group)
  end

  def self.make_remote_dir(host, directory)
    on(host, "test -d #{directory} || mkdir -p #{directory}")
  end

  def self.remote_dir_exists(host, directory)
    on(host, "test -d #{directory}")
  end

  def self.remote_file_exists(host, filepath)
    on(host, "test -f #{filepath}")
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
    result = self.agent_execute(ibm_install_pp)
    fail("IBM manager failed to install on [#{host}]") unless result.exit_code.to_s =~ /[0,2]/
  end

  def self.configure_master
    hosts.find{ |x| x.host_hash[:roles].include?('master') } ? master : fail("No master node detected by role!")
    make_remote_dir(master, HelperConstants.websphere_source_dir)

    unless remote_group(master, "system")
      on(master, "groupadd system")
    end
  end

  def self.mount_QA_resources
    nfs_pp = <<-MANIFEST
      file {"#{HelperConstants.qa_resources}":
        ensure => "directory",
      }

      if $::osfamily == 'Debian' {
        $pkg = "nfs-common"
      } else {
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
    result = self.agent_execute(nfs_pp)
    fail("nfs mount of QA software failed [#{HelperConstants.qa_resource_source}]") unless result.exit_code.to_s =~ /[0,2]/
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
