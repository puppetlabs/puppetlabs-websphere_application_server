require 'puppet/provider/websphere_helper'

Puppet::Type.type(:websphere_app_server).provide(:wsadmin, :parent => Puppet::Provider::Websphere_Helper) do

  def create
    #AdminTask.createApplicationServer('appNode01', '[-name asdf -templateName default -genUniquePorts true ]')
    cmd = "\"AdminTask.createApplicationServer('" + resource[:node]
    cmd += "', '[-name " + resource[:name] + ' -templateName default '
    cmd += "-genUniquePorts true ]')\""

    self.debug "Running #{cmd}"
    result = wsadmin(:command => cmd, :user => resource[:user])
    self.debug result
  end

  def exists?
    cmd = "\"print AdminTask.listServers()\""

    self.debug "Running #{cmd}"
    result = wsadmin(:command => cmd, :user => resource[:user])
    self.debug result

    unless result =~ /^#{resource[:name]}\(cells\/.*\/nodes\/#{resource[:node]}\/servers\/#{resource[:name]}/
      return false
    end
    true
  end

  def destroy
    cmd = "\"AdminTask.deleteServer('[-serverName #{resource[:name]} -nodeName #{resource[:node]} ]')\""

    self.debug "Running #{cmd}"
    result = wsadmin(:command => cmd, :user => resource[:user])
    self.debug result
  end

end
