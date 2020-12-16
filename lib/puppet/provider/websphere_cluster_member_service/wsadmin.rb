# frozen_string_literal: true

# Provider for managing websphere cluster members services.
#
# Each cluster member has a 'service' to enable/disable it with the cluster.
# This provider uses 'wsadmin' to handle the starting/stopping/restarting
# of the service.
#
require_relative '../websphere_helper'

Puppet::Type.type(:websphere_cluster_member_service).provide(:wsadmin, parent: Puppet::Provider::Websphere_Helper) do
  desc 'wsadmin provider for `websphere_cluster_member_service`'

  def self.instances
    []
  end

  def start
    cmd = "\"AdminControl.invoke(AdminControl.queryNames('WebSphere:*,type="
    cmd += "NodeAgent,node=%s' % '" + resource[:node_name] + "'), 'launchProcess',"
    cmd += "['" + resource[:name] + "'],['java.lang.String'])\""

    debug "Starting with command #{cmd}"

    result = wsadmin(command: cmd, user: resource[:user], failonfail: false)

    debug "Result: #{result}"

    ## If the command was successful, this will return the string 'true',
    ## including single quotes.
    return if result.include?("'true'")

    if %r{Error found in String ""; cannot create ObjectName}.match?(result)
      msg = <<-END
      Could not start cluster member #{resource[:name]}. The service on
      node #{resource[:node_name]} may not be running.
      END
      notice msg
    end
    raise Puppet::Error, 'There may have been a problem '\
      + "starting cluster member #{resource[:name]}"\
      + ' Run with --debug for details.'
  end

  def restart
    cmd = "\"the_id = AdminControl.queryNames('cell=" + resource[:cell]
    cmd += ',node=' + resource[:node_name] + ',j2eeType=J2EEServer,process='
    cmd += resource[:name] + ",*');"
    cmd += "AdminControl.invoke(the_id, 'restart', '[]', '[]')\""

    debug "Restarting with #{cmd}"
    result = wsadmin(command: cmd, user: resource[:user])

    debug "restart #{result}"
  end

  def stop
    cmd = "\"the_id = AdminControl.queryNames('cell=" + resource[:cell]
    cmd += ',node=' + resource[:node_name] + ',j2eeType=J2EEServer,process='
    cmd += resource[:name] + ",*');"
    cmd += "AdminControl.invoke(the_id, 'stop')\""

    debug "Stopping with #{cmd}"

    result = wsadmin(command: cmd, user: resource[:user])

    debug "stop: #{result}"

    raise Puppet::Error, "There may have been a problem  stopping cluster member #{resource[:name]} Run with --debug for details." unless result.include?("''")
  end

  def status
    return :running if running?
    :stopped
  end

  def running?
    cmd = wascmd
    cmd += "\"AdminControl.getAttribute(AdminControl.queryNames('WebSphere:*"
    cmd += ",type=Server,node=%s,process=%s' % ('"
    cmd += resource[:node_name] + "', '"
    cmd += resource[:name] + "')), 'state')\""

    ## This actually returns a scripting error if the thing isn't running and
    ## exits non-zero.
    ## TODO: use wsadmin
    result = `#{cmd}`
    debug "This will contain a ScriptingException error if it's "\
                 + "Not running. #{result}"
    if result.include?('STARTED')
      return true
    end
    false
  end
end
