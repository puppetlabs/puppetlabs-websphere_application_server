test_name 'FM-3808 - C94731 - Plug-in Sync Module from Master with Prerequisites Satisfied on Agent'

step 'Install puppetlabs-websphere_application_server Module Dependencies'
on(master, puppet('module install puppet-archive'))
on(master, puppet('module install puppetlabs-stdlib'))
on(master, puppet('module install puppetlabs-concat'))

# HACK to get IBM Installation Manager module onto the nodes from github
pp = <<-MANIFEST
    package{'wget':}
    exec{'download':
      command => "wget -P /root/ https://api.github.com/repos/puppetlabs/puppetlabs-ibm_installation_manager/tarball/master --no-check-certificate",
      path => ['/opt/csw/bin/','/usr/bin/']
    }
    exec{'rename':
      command => "mv /root/master /root/puppetlabs-ibm_installation_manager-0.1.2.tar.gz",
      path => ['/opt/csw/bin/', '/bin/']
    }
MANIFEST
# END HACK

create_remote_file(master, "/root/download.pp", pp)
on(master, "puppet apply /root/download.pp")
on(master, puppet('module install /root/puppetlabs-ibm_installation_manager-0.1.2.tar.gz --force'))

step 'Install ibm_installation_manager Module'
proj_root = File.expand_path(File.join(File.dirname(__FILE__), '../../../'))
staging = { :module_name => 'puppetlabs-websphere_application_server' }
local = { :module_name => 'websphere_application_server', :source => proj_root, :target_module_path => '/etc/puppetlabs/code/environments/production/modules' }

# in CI install from staging forge, otherwise from local
install_dev_puppet_module_on(master, options[:forge_host] ? staging : local)
