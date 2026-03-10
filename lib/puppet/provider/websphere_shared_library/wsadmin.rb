# frozen_string_literal: true

require_relative '../websphere_helper'
#
Puppet::Type.type(:websphere_shared_library).provide(:wsadmin, parent: Puppet::Provider::Websphere_Helper) do
  # @private
  # Helper method
  def scope(what)
    file = "#{resource[:profile_base]}/#{resource[:dmgr_profile]}"
    case resource[:scope]
    when 'cell'
      query = '/Cell:' + "#{resource[:cell]}/"
      file += "/config/cells/#{resource[:cell]}/libraries.xml"
    when 'node'
      query = '/Cell:' + "#{resource[:cell]}/" + 'Node:' + "#{resource[:node_name]}/"
      file += "/config/cells/#{resource[:cell]}/nodes/#{resource[:node_name]}/libraries.xml"
    when 'server'
      query = '/Cell:' + "#{resource[:cell]}/" + 'Node:' + "#{resource[:node_name]}/" + 'Server:' + "#{resource[:server]}/"
      file += "/config/cells/#{resource[:cell]}/nodes/#{resource[:node_name]}/servers/#{resource[:server]}/libraries.xml"
    when 'cluster'
      query = '/Cell:' + "#{resource[:cell]}/" + 'ServerCluster:' + "#{resource[:cluster]}/"
      file += "/config/cells/#{resource[:cell]}/clusters/#{resource[:cluster]}/libraries.xml"
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
  def get_property_value(prop)
    xml_file = scope('file')

    unless File.exist?(xml_file)
      return false
    end

    doc = REXML::Document.new(File.open(xml_file))

    path = XPath.first(doc, "//libraries:Library[@name='#{resource[:name]}']")
    value = XPath.first(path, "@#{prop}").to_s if path

    debug "Exists? Found match for #{resource[:name]}. #{prop} is: #{value}" if value
    value
  end

  # @private
  # Helper method
  def get_property_value_array(prop)
    xml_file = scope('file')

    unless File.exist?(xml_file)
      return false
    end

    doc = REXML::Document.new(File.open(xml_file))

    values = []
    XPath.each(doc, "//libraries:Library[@name='#{resource[:name]}']/#{prop}") do |el|
      values << el.text
    end
    debug "Exists? Found match for #{resource[:name]}. #{prop} is: #{values}" unless values.empty?
    values
  end

  def exists?
    xml_file = scope('file')

    unless File.exist?(xml_file)
      return false
    end

    doc = REXML::Document.new(File.open(xml_file))

    path = XPath.first(doc, "//libraries:Library[@name='#{resource[:name]}']")

    debug "Exists? Found match for #{resource[:name]}. Path #{path}" if path

    unless path
      debug "shared library #{resource[:name]} doesn't seem to exist"
      return false
    end

    true
  end

  def create
    class_paths = resource[:class_path].empty? ? '' : resource[:class_path].join(';')
    native_paths = resource[:native_path].empty? ? '' : resource[:native_path].join(';')
    attributes = [
      ['name', resource[:name]],
      ['classPath', class_paths], ['nativePath', native_paths],
      ['isolatedClassLoader', resource[:isolated_class_loader]],
      ['description', resource[:description]]
    ]

    cmd = <<-EOS
AdminConfig.create('Library', AdminConfig.getid('#{scope('query')}'), #{attributes})
AdminConfig.save()
EOS
    debug "Running #{cmd}"
    result = wsadmin(file: cmd, user: resource[:user])
    debug result
    @property_hash.clear
  end

  def class_path
    get_property_value_array('classPath')
  end

  def class_path=(value)
    @property_hash[:class_path] = value
  end

  def native_path
    get_property_value_array('nativePath')
  end

  def native_path=(value)
    @property_hash[:native_path] = value
  end

  def isolated_class_loader
    get_property_value('isolatedClassLoader')
  end

  def isolated_class_loader=(value)
    @property_hash[:isolated_class_loader] = value
  end

  def description
    get_property_value('description')
  end

  def description=(value)
    @property_hash[:description] = value
  end

  def destroy
    cmd = <<-EOS
AdminConfig.remove(AdminConfig.getid(\"#{scope('query')}Library:#{resource[:name]}\"))
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
    list_list << ['classPath', @property_hash[:class_path].join(';')] if @property_hash[:class_path]
    list_list << ['nativePath', @property_hash[:native_path].join(';')] if @property_hash[:native_path]
    list_list << ['isolatedClassLoader', @property_hash[:isolated_class_loader]] if @property_hash[:isolated_class_loader]
    list_list << ['description', @property_hash[:description]] if @property_hash[:description]
    list_list
  end

  def flush
    return if @property_hash.empty?
    cmd = <<-EOS
id = AdminConfig.getid(\"#{scope('query')}Library:#{resource[:name]}\")

# The modify command appends the specified unique classPath or nativePath values to the existing values.
# To completely replace the values, we must first remove the path attributes using the unsetAttributes command.
AdminConfig.unsetAttributes(id, '["classPath" "nativePath"]')

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
