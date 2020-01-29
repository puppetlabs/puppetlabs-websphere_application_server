require_relative '../websphere_helper'

Puppet::Type.type(:websphere_jaas_data).provide(:wsadmin, parent: Puppet::Provider::Websphere_Helper) do
  desc 'wsadmin provider for `websphere_jaas_data`'

  def scope(what)
    file = "#{resource[:profile_base]}/#{resource[:dmgr_profile]}"
    case resource[:scope]
    when 'cell'
      mod_path = "Cell=#{resource[:cell]}"
      get      = "Cell:#{resource[:cell]}"
      path     = "cells/#{resource[:cell]}"
      file << "/config/cells/#{resource[:cell]}/security.xml"
    when 'server'
      mod_path = "Cell=#{resource[:cell]},Server=#{resource[:server]}"
      get      = "Cell:#{resource[:cell]}/Node:#{resource[:node_name]}/Server:#{resource[:server]}"
      path     = "cells/#{resource[:cell]}/nodes/#{resource[:node_name]}/servers/#{resource[:server]}"
      file << "/config/cells/#{resource[:cell]}/nodes/#{resource[:node_name]}/servers/#{resource[:server]}/security.xml"
    when 'cluster'
      mod_path = "Cluster=#{resource[:cluster]}"
      get      = "Cell:#{resource[:cell]}/ServerCluster:#{resource[:cluster]}"
      path     = "cells/#{resource[:cell]}/clusters/#{resource[:cluster]}"
      file += "/config/cells/#{resource[:cell]}/clusters/#{resource[:cluster]}/security.xml"
    when 'node'
      mod_path = "Node=#{resource[:node_name]}"
      get      = "Cell:#{resource[:cell]}/Node:#{resource[:node_name]}"
      path     = "cells/#{resource[:cell]}/nodes/#{resource[:node_name]}"
      file << "/config/cells/#{resource[:cell]}/nodes/#{resource[:node_name]}/security.xml"
    end

    case what
    when 'mod'
      return mod_path
    when 'get'
      return get
    when 'path'
      return path
    when 'file'
      return file
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
    unless File.exist?(scope('file'))
      return false
    end

    debug "Retrieving value of #{resource[:name]} from #{scope('file')}"
    doc = REXML::Document.new(File.open(scope('file')))

    path = XPath.first(doc, "//authDataEntries[@alias='#{resource[:name]}']")
    value = XPath.first(path, '@alias') if path

    debug "Exists? #{resource[:name]} is: #{value}"

    !value.nil?
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
