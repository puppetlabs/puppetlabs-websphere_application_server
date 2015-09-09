require 'puppet/provider/websphere_helper'

Puppet::Type.type(:websphere_jdbc_provider).provide(:wsadmin, :parent => Puppet::Provider::Websphere_Helper) do

  def scope(what)
    case resource[:scope]
    when 'cell'
      mod_path = "Cell=#{resource[:cell]}"
      get      = "Cell:#{resource[:cell]}"
      path     = "cells/#{resource[:cell]}"
    when 'server'
      mod_path = "Cell=#{resource[:cell]},Server=#{resource[:server]}"
      get      = "Cell:#{resource[:cell]}/Node:#{resource[:node]}/Server:#{resource[:server]}"
      path     = "cells/#{resource[:cell]}/nodes/#{resource[:node]}/servers/#{resource[:server]}"
    when 'cluster'
      mod_path = "Cluster=#{resource[:cluster]}"
      get      = "Cell:#{resource[:cell]}/ServerCluster:#{resource[:cluster]}"
      path     = "cells/#{resource[:cell]}/clusters/#{resource[:cluster]}"
    when 'node'
      mod_path = "Node=#{resource[:node]}"
      get      = "Cell:#{resource[:cell]}/Node:#{resource[:node]}"
      path     = "cells/#{resource[:cell]}/nodes/#{resource[:node]}"
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

  def params_string
    params_list =  "-name \"#{resource[:name]}\" "
    params_list << "-scope #{scope('mod')} "
    params_list << "-databaseType #{resource[:dbtype]} "
    params_list << "-providerType \"#{resource[:providertype]}\" "
    params_list << "-implementationType \"#{resource[:implementation]}\" "
    params_list << "-description \"#{resource[:description]}\" " if resource[:description]
    params_list << "-classpath [ #{resource[:classpath]} ] " if resource[:classpath]
    params_list << "-nativePath \"#{resource[:native_path]}\" " if resource[:nativepath]

    params_list
  end

  def create
    cmd = "AdminTask.createJDBCProvider('[#{params_string}]'); AdminConfig.save()"

    self.debug "Creating JDBC Provider with #{cmd}"
    result = wsadmin(:file => cmd, :user => resource[:user])
    self.debug "Result: #{result}"

  end

  def exists?
    cmd = "\"print AdminConfig.list('JDBCProvider', AdminConfig.getid( '/"
    cmd << "#{scope('get')}/'))\""

    self.debug "Querying JDBC Provider with #{cmd}"
    result = wsadmin(:command => cmd, :user => resource[:user])
    self.debug "Result: #{result}"

    if result =~ /^"?#{resource[:name]}\(#{scope('path')}\|/
      self.debug "Found match for #{resource[:name]}"
      return true
    end

    self.debug "#{resource[:name]} doesn't seem to exist."
    return false

  end

  def destroy
    # AdminTask.deleteJDBCProvider('(cells/CELL_01|resources.xml#JDBCProvider_1422560538842)')
    Puppet.warning("Removal of JDBC Providers is not yet implemented")
  end

  def flush
    case resource[:scope]
    when /(server|node)/
      sync_node
    end
  end
end
