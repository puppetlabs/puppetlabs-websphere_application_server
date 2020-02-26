require_relative '../websphere_helper'

Puppet::Type.type(:websphere_cookie).provide(:wsadmin, parent: Puppet::Provider::Websphere_Helper) do
  desc 'wsadmin provider for `websphere_cookie`'

  def scope(what)
    file = "#{resource[:profile_base]}/#{resource[:dmgr_profile]}"
    case resource[:scope]
    when 'cell'
      mod_path = "Cell=#{resource[:cell]}"
      get      = "Cell:#{resource[:cell]}"
      path     = "cells/#{resource[:cell]}"
      file << "/config/cells/#{resource[:cell]}/cell.xml"
    when 'server'
      mod_path = "Cell=#{resource[:cell]},Server=#{resource[:server]}"
      get      = "Cell:#{resource[:cell]}/Node:#{resource[:node_name]}/Server:#{resource[:server]}"
      path     = "cells/#{resource[:cell]}/nodes/#{resource[:node_name]}/servers/#{resource[:server]}"
      file << "/config/cells/#{resource[:cell]}/nodes/#{resource[:node_name]}/servers/#{resource[:server]}/cell.xml"
    when 'cluster'
      mod_path = "Cluster=#{resource[:cluster]}"
      get      = "Cell:#{resource[:cell]}/ServerCluster:#{resource[:cluster]}"
      path     = "cells/#{resource[:cell]}/clusters/#{resource[:cluster]}"
      file += "/config/cells/#{resource[:cell]}/clusters/#{resource[:cluster]}/cell.xml"
    when 'node'
      mod_path = "Node=#{resource[:node_name]}"
      get      = "Cell:#{resource[:cell]}/Node:#{resource[:node_name]}"
      path     = "cells/#{resource[:cell]}/nodes/#{resource[:node_name]}"
      file << "/config/cells/#{resource[:cell]}/nodes/#{resource[:node_name]}/cell.xml"
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
    AdminTask.addDisabledSessionCookie('-cookieName #{resource[:name]} -cookiePath #{resource[:path]} -cookieDomain #{resource[:domain]}')
    AdminConfig.save()
    END

    debug "Creating Session Cookie: #{cmd}"
    result = wsadmin(file: cmd, user: resource[:user])
    debug "Result: #{result}"
  end

  def exists?
    unless File.exist?(scope('file'))
      return false
    end

    debug "Retrieving value of #{resource[:name]} from #{scope('file')}"
    doc = REXML::Document.new(File.open(scope('file')))

    path = XPath.first(doc, "//secureSessionCookie[@xmi:id='#{resource[:name]}']")
    value = XPath.first(path, '@xmi:id') if path

    debug "Exists? #{resource[:name]} is: #{value}"

    !value.nil?
  end

  def destroy
    cmd = <<-END.unindent
    # Remove #{resource[:name]} for #{scope('get')}
    AdminTask.removeDisabledSessionCookie('-cookieId cells/#{resource[:cell]}|cell.xml##{resource[:name]}')
    AdminConfig.save()
    END

    debug "Removing Session Cookie: #{cmd}"
    result = wsadmin(file: cmd, user: resource[:user])
    debug "Result: #{result}"
  end

  def flush
    case resource[:scope]
    when %r{(server|node)}
      sync_node
    end
  end
end
