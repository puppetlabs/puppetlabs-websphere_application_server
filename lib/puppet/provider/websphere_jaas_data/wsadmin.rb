require_relative '../websphere_helper'

Puppet::Type.type(:websphere_jaas_data).provide(:wsadmin, parent: Puppet::Provider::Websphere_Helper) do
  desc 'wsadmin provider for `websphere_jaas_data`'

  def scope(what)
    case resource[:scope]
    when 'cell'
      mod_path = "Cell=#{resource[:cell]}"
      get      = "Cell:#{resource[:cell]}"
      path     = "cells/#{resource[:cell]}"
    when 'server'
      mod_path = "Cell=#{resource[:cell]},Server=#{resource[:server]}"
      get      = "Cell:#{resource[:cell]}/Node:#{resource[:node_name]}/Server:#{resource[:server]}"
      path     = "cells/#{resource[:cell]}/nodes/#{resource[:node_name]}/servers/#{resource[:server]}"
    when 'cluster'
      mod_path = "Cluster=#{resource[:cluster]}"
      get      = "Cell:#{resource[:cell]}/ServerCluster:#{resource[:cluster]}"
      path     = "cells/#{resource[:cell]}/clusters/#{resource[:cluster]}"
    when 'node'
      mod_path = "Node=#{resource[:node_name]}"
      get      = "Cell:#{resource[:cell]}/Node:#{resource[:node_name]}"
      path     = "cells/#{resource[:cell]}/nodes/#{resource[:node_name]}"
    end

    case what
    when 'mod'
      return mod_path
    when 'get'
      return get
    when 'path'
      return path
    end
  end

  def create
    cmd = <<-END.unindent
    # Create #{resource[:name]} for #{resource[:cell]}
    sec = AdminConfig.getid('/Cell:#{resource[:cell]}/Security:/')

    alias_attr = ["alias", "#{resource[:name]}"]
    desc_attr = ["description", "authentication information, Created by Puppet"]
    userid_attr = ["userId", "#{resource[:username]}"]
    password_attr = ["password", "#{resource[:password]}"]
    attrs = [alias_attr, desc_attr, userid_attr, password_attr]
    AdminConfig.create("JAASAuthData", sec, attrs)

    AdminConfig.save()
    END

    debug "Creating JAAS Config Data with #{cmd}"
    result = wsadmin(file: cmd, user: resource[:user])
    debug "Result: #{result}"
  end

  def exists?
    cmd = <<-END.unindent
    AdminConfig.list("JAASAuthData")
    END

    debug "Get JAAS Config Data #{cmd}"
    result = wsadmin(file: cmd, user: resource[:user])
    debug "Result: #{result}"

    false # always false for now
  end

  def destroy
    Puppet.warning('Removal of JAAS Config Data is not yet implemented')
  end

  def flush
    case resource[:scope]
    when %r{(server|node)}
      sync_node
    end
  end
end
