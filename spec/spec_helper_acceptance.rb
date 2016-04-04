require 'beaker-rspec'
require 'beaker/puppet_install_helper'

run_puppet_install_helper

UNSUPPORTED_PLATFORMS = ['Suse','windows','AIX','Solaris']

RSpec.configure do |c|
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  c.formatter = :documentation

  unless ENV["RS_PROVISION"] == "no" or ENV["BEAKER_provision"] == "no"
    on master, puppet('module','install','puppetlabs-stdlib'), { :acceptable_exit_codes => [0,1] }
    on master, puppet('module','install','puppetlabs-concat'), { :acceptable_exit_codes => [0,1] }
    on master, puppet('module','install','nanliu-staging'), { :acceptable_exit_codes => [0,1] }

    # HACK to get IBM Installation Manager module onto the nodes from github
    pp = <<-EOS
    package{'wget':}
    exec{'download':
      command => "wget -P /root/ https://api.github.com/repos/puppetlabs/puppetlabs-ibm_installation_manager/tarball/master --no-check-certificate",
      path => ['/opt/csw/bin/','/usr/bin/']
    }
    exec{'rename':
      command => "mv /root/master /root/puppetlabs-ibm_installation_manager-0.1.2.tar.gz",
      path => ['/opt/csw/bin/', '/bin/']
    }
    EOS
    # END HACK

    apply_manifest_on(master, pp)
    on master, puppet('module install /root/puppetlabs-ibm_installation_manager-0.1.2.tar.gz --force')
  end

  # Configure all nodes in nodeset
  c.before :suite do
    copy_module_to(master, :source => proj_root, :module_name => 'websphere_application_server')
  end
end

