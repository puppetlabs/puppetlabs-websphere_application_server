require_relative '../websphere_helper'

Puppet::Type.type(:websphere_app_server).provide(:wsadmin, parent: Puppet::Provider::Websphere_Helper) do
  desc 'wsadmin provider for `websphere_app_server`'

  def create
    # AdminTask.createApplicationServer('appNode01', '[-name asdf -templateName default -genUniquePorts true ]')
    cmd = "\"AdminTask.createApplicationServer('" + resource[:node_name]
    cmd += "', '[-name " + resource[:name] + ' -templateName default '
    cmd += "-genUniquePorts true ]')\""

    debug "Running #{cmd}"
    result = wsadmin(command: cmd, user: resource[:user])
    debug result
  end

  def exists?
    cmd = '"print AdminTask.listServers()"'

    debug "Running #{cmd}"
    result = wsadmin(command: cmd, user: resource[:user])
    debug result

    unless result =~ %r{^#{resource[:name]}\(cells/.*/nodes/#{resource[:node_name]}/servers/#{resource[:name]}}
      return false
    end
    true
  end

  def destroy
    cmd = "\"AdminTask.deleteServer('[-serverName #{resource[:name]} -nodeName #{resource[:node_name]} ]')\""

    debug "Running #{cmd}"
    result = wsadmin(command: cmd, user: resource[:user])
    debug result
  end
end
