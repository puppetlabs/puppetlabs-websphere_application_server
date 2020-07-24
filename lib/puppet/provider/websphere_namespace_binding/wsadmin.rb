require_relative '../websphere_helper'
#
Puppet::Type.type(:websphere_namespace_binding).provide(:wsadmin, parent: Puppet::Provider::Websphere_Helper) do
  # @private
  # Helper method
  def scope(what)
    file = "#{resource[:profile_base]}/#{resource[:dmgr_profile]}"
    case resource[:scope]
    when 'cell'
      query = '/Cell:' + "#{resource[:cell]}/"
      file += "/config/cells/#{resource[:cell]}/namebindings.xml"
    when 'node'
      query = '/Cell:' + "#{resource[:cell]}/" + 'Node:' + "#{resource[:node_name]}/"
      file += "/config/cells/#{resource[:cell]}/nodes/#{resource[:node_name]}/namebindings.xml"
    when 'server'
      query = '/Cell:' + "#{resource[:cell]}/" + 'Node:' + "#{resource[:node_name]}/" + 'Server:' + "#{resource[:server]}/"
      file += "/config/cells/#{resource[:cell]}/nodes/#{resource[:node_name]}/servers/#{resource[:server]}/namebindings.xml"
    when 'cluster'
      query = '/Cell:' + "#{resource[:cell]}/" + 'ServerCluster:' + "#{resource[:cluster]}/"
      file += "/config/cells/#{resource[:cell]}/clusters/#{resource[:cluster]}/namebindings.xml"
    else
      raise Puppet::Error, "Unknown scope: #{resource[:scope]}"
    end

    case what
    when 'query'
      query
    when 'file'
      file
    else
      debug 'Invalid scope request'
    end
  end

  # @private
  # Helper method
  # Need to have double quotes around the values within the command
  def bind(what)
    scope = scope('query')

    case resource[:binding_type]
    when 'string'
      cmd = '"' + "AdminConfig.create('StringNameSpaceBinding', AdminConfig.getid("
      cmd += "'#{scope}'),'["
      cmd += '[name ' + '\"' + resource[:name] + '\"] '
      cmd += '[nameInNameSpace ' + '\"' + resource[:name_in_name_space] + '\"] '
      cmd += '[stringToBind ' + '\"' + resource[:string_to_bind] + '\"]' + "]')" + '"'
      object = 'StringNameSpaceBinding'
    when 'ejb'
      cmd =  '"' + "AdminConfig.create('EjbNameSpaceBinding', AdminConfig.getid("
      cmd += "'#{scope}'),'["
      cmd += '[name ' + '\"' + resource[:name] + '\"] '
      cmd += '[nameInNameSpace ' + '\"' + resource[:name_in_name_space] + '\"] '
      cmd += '[ejbJndiName ' + '\"' + resource[:ejb_jndi_name] + '\"] '
      cmd += '[applicationServerName ' + '\"' + resource[:application_server_name] + '\"] ' if resource[:application_server_name]
      cmd += '[applicationNodeName ' + '\"' + resource[:application_node_name] + '\"]' if resource[:application_node_name]
      cmd += "]')" + '"'
      object = 'EjbNameSpaceBinding'
    when 'corba'
      cmd = '"' + "AdminConfig.create('CORBAObjectNameSpaceBinding', AdminConfig.getid("
      cmd += "'#{scope}'),'["
      cmd += '[name ' + '\"' + resource[:name] + '\"] '
      cmd += '[nameInNameSpace ' + '\"' + resource[:name_in_name_space] + '\"] '
      cmd += '[corbanameUrl ' + '\"' + resource[:corbaname_url] + '\"] '
      cmd += '[federatedContext ' + '\"' + resource[:federated_context] + '\"]' + "]')" + '"'
      object = 'CORBAObjectNameSpaceBinding'
    when 'indirect'
      cmd = '"' + "AdminConfig.create('IndirectLookupNameSpaceBinding', AdminConfig.getid("
      cmd += "'#{scope}'),'["
      cmd += '[name ' + '\"' + resource[:name] + '\"] '
      cmd += '[nameInNameSpace ' + '\"' + resource[:name_in_name_space] + '\"] '
      cmd += '[providerURL ' + '\"' + resource[:provider_url] + '\"] '
      cmd += '[initialContextFactory ' + '\"' + resource[:initial_context_factory] + '\"] '
      cmd += '[jndiName ' + '\"' + resource[:jndi_name] + '\"]' + "]')" + '"'
      object = 'IndirectLookupNameSpaceBinding'
    else
      raise Puppet::Error, "Unknown binding_type: #{resource[:binding_type]}"
    end

    case what
    when 'cmd'
      cmd
    when 'object'
      object
    else
      debug 'Invalid object request'
    end
  end

  # @private
  # Helper method
  def get_property_value(prop)
    bind_object = bind('object')
    name_bindings_xml = scope('file')

    unless File.exist?(name_bindings_xml)
      return false
    end

    doc = REXML::Document.new(File.open(name_bindings_xml))

    path = XPath.first(doc, "//namebindings:#{bind_object}[@name='#{resource[:name]}']")
    value = XPath.first(path, "@#{prop}").to_s if path

    debug "Exists? Found match for #{resource[:name]}. #{prop} is: #{value}" if value
    value
  end

  def exists?
    bind_object = bind('object')
    name_bindings_xml = scope('file')

    unless File.exist?(name_bindings_xml)
      return false
    end

    doc = REXML::Document.new(File.open(name_bindings_xml))

    path = XPath.first(doc, "//namebindings:#{bind_object}[@name='#{resource[:name]}']")

    debug "Exists? Found match for #{resource[:name]}. Path #{path}" if path

    unless path
      debug "namespace binding #{resource[:name]} doesn't seem to exist"
      return false
    end

    true
  end

  def create
    cmd = bind('cmd')
    debug "Running #{cmd}"
    result = wsadmin(command: cmd, user: resource[:user])
    debug result
    @property_hash.clear
  end

  def name_in_name_space
    get_property_value('nameInNameSpace')
  end

  def name_in_name_space=(value)
    @property_hash[:name_in_name_space] = value
  end

  # corba
  def corbaname_url
    unless resource[:binding_type] == 'corba'
      return nil
    end
    get_property_value('corbanameUrl')
  end

  # corba
  def corbaname_url=(value)
    @property_hash[:corbaname_url] = value
  end

  # corba
  def federated_context
    unless resource[:binding_type] == 'corba'
      return nil
    end
    get_property_value('federatedContext')
  end

  # corba
  def federated_context=(value)
    @property_hash[:federated_context] = value
  end

  # string
  def string_to_bind
    unless resource[:binding_type] == 'string'
      return nil
    end
    get_property_value('stringToBind')
  end

  # string
  def string_to_bind=(value)
    @property_hash[:string_to_bind] = value
  end

  # ejb
  def application_node_name
    unless resource[:binding_type] == 'ejb'
      return nil
    end
    get_property_value('applicationNodeName')
  end

  # ejb
  def application_node_name=(value)
    @property_hash[:application_node_name] = value
  end

  # ejb
  def application_server_name
    unless resource[:binding_type] == 'ejb'
      return nil
    end
    get_property_value('applicationServerName')
  end

  # ejb
  def application_server_name=(value)
    @property_hash[:application_server_name] = value
  end

  # ejb
  def ejb_jndi_name
    unless resource[:binding_type] == 'ejb'
      return nil
    end
    get_property_value('ejbJndiName')
  end

  # ejb
  def ejb_jndi_name=(value)
    @property_hash[:ejb_jndi_name] = value
  end

  # indirect
  def provider_url
    unless resource[:binding_type] == 'indirect'
      return nil
    end
    get_property_value('providerURL')
  end

  # indirect
  def provider_url=(value)
    @property_hash[:provider_url] = value
  end

  # indirect
  def initial_context_factory
    unless resource[:binding_type] == 'indirect'
      return nil
    end
    get_property_value('initialContextFactory')
  end

  # indirect
  def initial_context_factory=(value)
    @property_hash[:initial_context_factory] = value
  end

  # indirect
  def jndi_name
    unless resource[:binding_type] == 'indirect'
      return nil
    end
    get_property_value('jndiName')
  end

  # indirect
  def jndi_name=(value)
    @property_hash[:jndi_name] = value
  end

  def destroy
    cmd = <<-EOS
AdminConfig.remove(AdminConfig.getid(\"#{scope('query')}#{bind('object')}:#{resource[:name]}\"))
AdminConfig.save()
EOS
    debug "Running #{cmd}"
    result = wsadmin(file: cmd, user: resource[:user])
    debug result
    @property_hash.clear
  end

  # @private
  # Helper method
  def modified_attributes_list_list
    # Only add defined values
    list_list = []
    list_list << ['nameInNameSpace', @property_hash[:name_in_name_space]] if @property_hash[:name_in_name_space]
    list_list << ['corbanameUrl', @property_hash[:corbaname_url]] if @property_hash[:corbaname_url]
    list_list << ['federatedContext', @property_hash[:federated_context]] if @property_hash[:federated_context]
    list_list << ['stringToBind', @property_hash[:string_to_bind]] if @property_hash[:string_to_bind]
    list_list << ['applicationNodeName', @property_hash[:application_node_name]] if @property_hash[:application_node_name]
    list_list << ['applicationServerName', @property_hash[:application_server_name]] if @property_hash[:application_server_name]
    list_list << ['ejbJndiName', @property_hash[:ejb_jndi_name]] if @property_hash[:ejb_jndi_name]
    list_list << ['providerURL', @property_hash[:provider_url]] if @property_hash[:provider_url]
    list_list << ['initialContextFactory', @property_hash[:initial_context_factory]] if @property_hash[:initial_context_factory]
    list_list << ['jndiName', @property_hash[:jndi_name]] if @property_hash[:jndi_name]
    list_list
  end

  def flush
    return if @property_hash.empty?
    cmd = <<-EOS
id = AdminConfig.getid(\"#{scope('query')}#{bind('object')}:#{resource[:name]}\")
AdminConfig.modify(id, #{modified_attributes_list_list})
AdminConfig.save()
EOS
    debug 'flushing namespace bindings'
    debug "Running #{cmd}"
    result = wsadmin(file: cmd, user: resource[:user])
    debug result
    case resource[:scope]
    when %r{(server|node)}
      sync_node
    end
  end
end
