require 'beaker-rspec'
require 'beaker/puppet_install_helper'

run_puppet_install_helper

UNSUPPORTED_PLATFORMS = ['Suse','windows','AIX','Solaris']

RSpec.configure do |c|
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  c.formatter = :documentation

  unless ENV["RS_PROVISION"] == "no" or ENV["BEAKER_provision"] == "no"
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

