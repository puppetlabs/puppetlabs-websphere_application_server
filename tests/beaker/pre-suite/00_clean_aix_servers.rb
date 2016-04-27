# This step is to clean the AIX servers: uninstall Puppet Agent

confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    if (agent['platform'] =~ /aix/)
      step 'Cleaning AIX server...'
      on(agent, "echo -e \"y\ny\ny\n\" | /enterprise-dist/installer/puppet-enterprise-uninstaller")
      on(agent, "rm -rf /opt/puppetlabs /tmp/*")
    end
  end
end
