require_relative '../websphere_helper'

Puppet::Type.type(:websphere_namespace_binding).provide(:wsadmin, parent: Puppet::Provider::Websphere_Helper) do
  desc 'wsadmin provider for `websphere_namespace_binding`'

  def scope(what)
    file = "#{resource[:profile_base]}/#{resource[:dmgr_profile]}"
    case resource[:scope]
    when 'cell'
      mod_path = "Cell=#{resource[:cell]}"
      get      = "Cell:#{resource[:cell]}"
      path     = "cells/#{resource[:cell]}"
      file << "/config/cells/#{resource[:cell]}/namebindings.xml"
    when 'server'
      mod_path = "Cell=#{resource[:cell]},Server=#{resource[:server]}"
      get      = "Cell:#{resource[:cell]}/Node:#{resource[:node_name]}/Server:#{resource[:server]}"
      path     = "cells/#{resource[:cell]}/nodes/#{resource[:node_name]}/servers/#{resource[:server]}"
      file << "/config/cells/#{resource[:cell]}/nodes/#{resource[:node_name]}/servers/#{resource[:server]}/namebindings.xml"
    when 'cluster'
      mod_path = "Cluster=#{resource[:cluster]}"
      get      = "Cell:#{resource[:cell]}/ServerCluster:#{resource[:cluster]}"
      path     = "cells/#{resource[:cell]}/clusters/#{resource[:cluster]}"
      file += "/config/cells/#{resource[:cell]}/clusters/#{resource[:cluster]}/namebindings.xml"
    when 'node'
      mod_path = "Node=#{resource[:node_name]}"
      get      = "Cell:#{resource[:cell]}/Node:#{resource[:node_name]}"
      path     = "cells/#{resource[:cell]}/nodes/#{resource[:node_name]}"
      file << "/config/cells/#{resource[:cell]}/nodes/#{resource[:node_name]}/namebindings.xml"
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
    # Create #{resource[:name]} for #{scope('get')}
    cell = AdminConfig.getid('/#{scope('get')}/')

    AdminConfig.create('StringNameSpaceBinding', cell, [['name', '#{resource[:name]}'],  
    ['nameInNameSpace', "#{resource[:binding_name]}"], ['stringToBind', "#{resource[:binding_value]}"]])
    AdminConfig.save()
    END

    debug "Creating StringNameSpaceBinding Config Data with #{cmd}"
    result = wsadmin(file: cmd, user: resource[:user])
    debug "Result: #{result}"
  end

  def exists?
    unless File.exist?(scope('file'))
      return false
    end

    debug "Retrieving value of #{resource[:name]} from #{scope('file')}"
    doc = REXML::Document.new(File.open(scope('file')))

    path = XPath.first(doc, "//namebindings:StringNameSpaceBinding[@name='#{resource[:name]}']")
    value = XPath.first(path, '@name') if path

    debug "Exists? #{resource[:name]} is: #{value}"

    !value.nil?
  end

  def destroy
    Puppet.warning('Removal of Namespace Binding Config Data is not yet implemented')
  end

  def flush
    case resource[:scope]
    when %r{(server|node)}
      sync_node
    end
  end
end
