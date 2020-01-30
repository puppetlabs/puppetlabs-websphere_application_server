require_relative '../websphere_helper'

Puppet::Type.type(:websphere_jdbc_datasource).provide(:wsadmin, parent: Puppet::Provider::Websphere_Helper) do
  desc 'wsadmin provider for `websphere_jdbc_datasource`'

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

  def config_props
    case resource[:data_store_helper_class]
    when 'com.ibm.websphere.rsadapter.DB2UniversalDataStoreHelper'
      configprop = "[[databaseName \"java.lang.String #{resource[:database]}\"] "
      configprop += "[driverType java.lang.Integer #{resource[:db2_driver]}] "
      configprop += "[serverName \"java.lang.String #{resource[:db_server]}\"] "
      configprop += "[portNumber java.lang.Integer #{resource[:db_port]}]]"
    when 'com.ibm.websphere.rsadapter.MicrosoftSQLServerDataStoreHelper'
      configprop = "[[databaseName \"java.lang.String #{resource[:database]}\"] "
      configprop += "[portNumber java.lang.Integer #{resource[:db_port]}] "
      configprop += "[serverName \"java.lang.String #{resource[:db_server]}\"]]"
    when 'com.ibm.websphere.rsadapter.Oracle11gDataStoreHelper'
      configprop = "[[URL java.lang.String \"#{resource[:url]}\"]]"
    else
      raise Puppet::Error, "Can't deal with #{resource[:data_store_helper_class]}"
    end

    configprop
  end

  def params_string
    params_list =  "-name \"#{resource[:name]}\" "
    params_list << "-jndiName \"#{resource[:jndi_name]}\" "
    params_list << "-dataStoreHelperClassName #{resource[:data_store_helper_class]} "
    params_list << "-configureResourceProperties #{config_props} "
    # append optional parameters
    #
    params_list << "-authDataAlias \"#{resource[:jaas_alias]}\" " if resource[:jaas_alias]
    params_list << "-mappingConfigAlias \"#{resource[:jaas_alias_mapping]}\" " if resource[:jaas_alias_mapping]
    params_list << "-containerManagedPersistence #{resource[:container_managed_persistence]} " if resource[:container_managed_persistence]
    params_list << "-componentManagedAuthenticationAlias \"#{resource[:component_managed_auth_alias]}\" " if resource[:component_managed_auth_alias]
    params_list << "-description \"#{resource[:description]}\" " if resource[:description]

    params_list
  end

  def create
    cmd = <<-EOS
provider = AdminConfig.getid('/#{scope('get')}/JDBCProvider:#{resource[:jdbc_provider]}/')
AdminTask.createDatasource(provider, '[#{params_string}]')
AdminConfig.save()
EOS
    # rubocop:enable Layout/IndentHeredoc

    debug "Creating JDBC Datasource with:\n#{cmd}"
    result = wsadmin(file: cmd, user: resource[:user])
    debug "Result:\n#{result}"
  end

  def exists?
    cmd = "\"print AdminConfig.list('DataSource', AdminConfig.getid( '/"
    cmd << "#{scope('get')}/'))\""

    debug "Querying JDBC Datasource with #{cmd}"
    result = wsadmin(command: cmd, user: resource[:user])
    debug "Result: #{result}"

    if result =~ %r{^"?#{resource[:name]}\(#{scope('path')}\|}
      debug "Found match for #{resource[:name]}"
      return true
    end

    debug "Datasource #{resource[:name]} doesn't seem to exist in #{scope('path')}"
    false
  end

  def destroy
    # AdminTask.deleteJDBCProvider('(cells/CELL_01|resources.xml#JDBCProvider_1422560538842)')
    Puppet.warning('Removal of JDBC Providers is not yet implemented')
  end

  def flush
    case resource[:scope]
    when %r{(server|node)}
      sync_node
    end
  end
end
