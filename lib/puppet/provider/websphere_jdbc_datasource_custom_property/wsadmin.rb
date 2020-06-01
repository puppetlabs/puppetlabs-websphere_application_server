require_relative '../websphere_helper'
#
Puppet::Type.type(:websphere_jdbc_datasource_custom_property).provide(:wsadmin, parent: Puppet::Provider::Websphere_Helper) do
  # @private
  # Helper method
  def scope(what)
    file = "#{resource[:profile_base]}/#{resource[:dmgr_profile]}"
    case resource[:scope]
    when 'cell'
      query = '/Cell:' + "#{resource[:cell]}/JDBCProvider:#{resource[:jdbc_provider]}/DataSource:#{resource[:jdbc_datasource]}/"
      file += "/config/cells/#{resource[:cell]}/resources.xml"
    when 'node'
      query = '/Cell:' + "#{resource[:cell]}/" + 'Node:' + "#{resource[:node_name]}/JDBCProvider:#{resource[:jdbc_provider]}/DataSource:#{resource[:jdbc_datasource]}/"
      file += "/config/cells/#{resource[:cell]}/nodes/#{resource[:node_name]}/resources.xml"
    when 'server'
      # rubocop:disable Metrics/LineLength
      query = '/Cell:' + "#{resource[:cell]}/" + 'Node:' + "#{resource[:node_name]}/" + 'Server:' + "#{resource[:server]}/JDBCProvider:#{resource[:jdbc_provider]}/DataSource:#{resource[:jdbc_datasource]}/"
      # rubocop:enable Metrics/LineLength
      file += "/config/cells/#{resource[:cell]}/nodes/#{resource[:node_name]}/servers/#{resource[:server]}/resources.xml"
    when 'cluster'
      query = '/Cell:' + "#{resource[:cell]}/" + 'ServerCluster:' + "#{resource[:cluster]}/JDBCProvider:#{resource[:jdbc_provider]}/DataSource:#{resource[:jdbc_datasource]}/"
      file += "/config/cells/#{resource[:cell]}/clusters/#{resource[:cluster]}/resources.xml"
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
  def resource_xpath
    "//resources.jdbc:JDBCProvider[@name='#{resource[:jdbc_provider]}']/factories[@name='#{resource[:jdbc_datasource]}']/propertySet/resourceProperties[@name='#{resource[:name]}']"
  end

  # @private
  # Helper method
  def get_property_value(prop)
    xml_file = scope('file')
    doc = REXML::Document.new(File.open(xml_file))
    path = REXML::XPath.first(doc, resource_xpath)
    value = REXML::XPath.first(path, "@#{prop}").to_s if path

    debug "Exists? Found match for #{resource[:name]}. #{prop} is: #{value}" if value
    value
  end

  def exists?
    xml_file = scope('file')

    unless File.exist?(xml_file)
      return false
    end

    doc = REXML::Document.new(File.open(xml_file))

    jdbc_provider_path = XPath.first(doc, "//resources.jdbc:JDBCProvider[@name='#{resource[:jdbc_provider]}']")
    raise Puppet::Error, "JDBC provider #{resource[:jdbc_provider]} does not exist. Cannot create custom property: #{resource[:name]}." unless jdbc_provider_path
    jdbc_datasource_path = XPath.first(jdbc_provider_path, "factories[@name='#{resource[:jdbc_datasource]}']")
    raise Puppet::Error, "JDBC datasource #{resource[:jdbc_datasource]} does not exist for #{resource[:jdbc_provider]}. Cannot create custom property: #{resource[:name]}." unless jdbc_datasource_path
    custom_property_path = XPath.first(jdbc_datasource_path, "propertySet/resourceProperties[@name='#{resource[:name]}']")

    debug "Exists? Found match for #{resource[:name]}. Path #{custom_property_path}" if custom_property_path

    unless custom_property_path
      debug "jdbc datasource custom property #{resource[:name]} doesn't seem to exist."
      return false
    end

    true
  end

  def create
    attributes = [
      ['name', resource[:name]],
      ['type', "java.lang.#{resource[:java_type]}"],
      ['value', resource[:property_value]],
    ]
    attributes << ['description', resource[:description]] if resource[:description]

    cmd = <<-EOS
id = AdminConfig.getid('#{scope('query')}')
propSet = AdminConfig.showAttribute(id, 'propertySet')
AdminConfig.create('J2EEResourceProperty', propSet, #{attributes})
AdminConfig.save()
EOS
    debug "Running #{cmd}"
    result = wsadmin(file: cmd, user: resource[:user])
    debug result
    @property_hash.clear
  end

  def property_value
    get_property_value('value')
  end

  def property_value=(value)
    @property_hash[:property_value] = value
  end

  def description
    get_property_value('description')
  end

  def description=(value)
    @property_hash[:description] = value
  end

  def destroy
    cmd = <<-EOS
AdminConfig.remove(AdminConfig.getid("#{scope('query')}J2EEResourcePropertySet:/J2EEResourceProperty:#{resource[:name]}"))
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
    list_list << ['value', @property_hash[:property_value]] if @property_hash[:property_value]
    list_list << ['description', @property_hash[:description]] if @property_hash[:description]
    list_list
  end

  def flush
    return if @property_hash.empty?
    cmd = <<-EOS
id = AdminConfig.getid("#{scope('query')}J2EEResourcePropertySet:/J2EEResourceProperty:#{resource[:name]}")
AdminConfig.modify(id, #{modified_attributes_list_list})
AdminConfig.save()
EOS
    debug "Running #{cmd}"
    result = wsadmin(file: cmd, user: resource[:user])
    debug result
    case resource[:scope]
    when %r{(server|node)}
      sync_node
    end
  end
end
