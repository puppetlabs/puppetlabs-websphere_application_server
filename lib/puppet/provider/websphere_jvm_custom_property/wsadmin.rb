# frozen_string_literal: true

require_relative '../websphere_helper'
#
Puppet::Type.type(:websphere_jvm_custom_property).provide(:wsadmin, parent: Puppet::Provider::Websphere_Helper) do
  # @private
  # Helper method
  def get_property_value(prop)
    xml_file = "#{resource[:profile_base]}/#{resource[:dmgr_profile]}/config/cells/#{resource[:cell]}/nodes/#{resource[:node_name]}/servers/#{resource[:server]}/server.xml"
    doc = REXML::Document.new(File.open(xml_file))
    path = REXML::XPath.first(doc, "//processDefinitions/jvmEntries/systemProperties[@name='#{resource[:name]}']")
    value = REXML::XPath.first(path, "@#{prop}").to_s if path

    debug "Exists? Found match for #{resource[:name]}. #{prop} is: #{value}" if value
    value
  end

  def exists?
    xml_file = "#{resource[:profile_base]}/#{resource[:dmgr_profile]}/config/cells/#{resource[:cell]}/nodes/#{resource[:node_name]}/servers/#{resource[:server]}/server.xml"

    unless File.exist?(xml_file)
      return false
    end

    doc = REXML::Document.new(File.open(xml_file))

    path = XPath.first(doc, "//processDefinitions/jvmEntries/systemProperties[@name='#{resource[:name]}']")

    debug "Exists? Found match for #{resource[:name]}. Path #{path}" if path

    unless path
      debug "custom property #{resource[:name]} doesn't seem to exist."
      return false
    end

    true
  end

  def create
    attributes = [
      ['name', resource[:name]],
      ['value', resource[:property_value]],
    ]
    attributes << ['description', resource[:description]] if resource[:description]

    query = '/Cell:' + "#{resource[:cell]}/" + 'Node:' + "#{resource[:node_name]}/" + 'Server:' + "#{resource[:server]}/JavaProcessDef:/JavaVirtualMachine:/"
    cmd = <<-EOS
id = AdminConfig.getid('#{query}')
AdminConfig.create('Property', id, #{attributes})
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
    query = '/Cell:' + "#{resource[:cell]}/" + 'Node:' + "#{resource[:node_name]}/" + 'Server:' + "#{resource[:server]}/JavaProcessDef:/JavaVirtualMachine:/Property:#{resource[:name]}/"
    cmd = <<-EOS
AdminConfig.remove(AdminConfig.getid("#{query}"))
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
    query = '/Cell:' + "#{resource[:cell]}/" + 'Node:' + "#{resource[:node_name]}/" + 'Server:' + "#{resource[:server]}/JavaProcessDef:/JavaVirtualMachine:/Property:#{resource[:name]}/"
    cmd = <<-EOS
id = AdminConfig.getid("#{query}")
AdminConfig.modify(id, #{modified_attributes_list_list})
AdminConfig.save()
EOS
    debug "Running #{cmd}"
    result = wsadmin(file: cmd, user: resource[:user])
    debug result
    sync_node
  end
end
