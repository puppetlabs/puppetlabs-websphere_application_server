# frozen_string_literal: true

require_relative '../websphere_helper'
#
Puppet::Type.type(:websphere_security_custom_property).provide(:wsadmin, parent: Puppet::Provider::Websphere_Helper) do
  desc 'wsadmin provider for `websphere_security_custom_property`'

  # @private
  # Helper method
  def get_property_value(prop)
    xml_file = resource[:profile_base] + '/' + resource[:profile] + '/config/cells/' + resource[:cell] + '/security.xml'
    return nil unless File.exist?(xml_file)
    doc = REXML::Document.new(File.open(xml_file))
    path = REXML::XPath.first(doc, "//properties[@name='#{resource[:name]}']")
    value = REXML::XPath.first(path, "@#{prop}").to_s if path

    debug "Exists? Found match for #{resource[:name]}. #{prop} is: #{value}" if value
    value
  end

  def exists?
    security_xml = resource[:profile_base] + '/' + resource[:profile] + '/config/cells/' + resource[:cell] + '/security.xml'

    return false unless File.exist?(security_xml)

    doc = REXML::Document.new(File.open(security_xml))

    path = XPath.first(doc, "//properties[@name='#{resource[:name]}']")
    debug "Exists? Found match for #{resource[:name]}. Path #{path}" if path

    unless path
      debug "Security custom property #{resource[:name]} does not exist."
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

    cmd = <<-EOS
security = AdminConfig.getid('/Cell:#{resource[:cell]}/Security:/');
AdminConfig.create('Property', security, #{attributes});
AdminConfig.save();
EOS
    debug "Running #{cmd}"
    result = wsadmin(file: cmd, user: resource[:user])
    debug "Created Security Custom Property. result: #{result}"
  end

  def destroy
    # AdminConfig.remove('(cells/CELL_01|security.xml#Property_1587485876321)')
    # AdminConfig.getid('/Security:/Property:com.ibm.websphere.tls.disabledAlgorithms')
    cmd = <<-EOT
    \"AdminConfig.remove(AdminConfig.getid('/Cell:#{resource[:cell]}/Security:/Property:#{resource[:name]}/'))
    AdminConfig.save()\"
    EOT
    debug "Running #{cmd}"
    result = wsadmin(command: cmd, user: resource[:user])
    debug "Removed Security Custom Property #{resource[:name]}. result: #{result}"
  end

  def property_value
    value = get_property_value('value')
    value = value.gsub(%r{&lt;}, '<')
    value = value.gsub(%r{&gt;}, '>')
    value
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
id = AdminConfig.getid('/Cell:#{resource[:cell]}/Security:/Property:#{resource[:name]}')
AdminConfig.modify(id, #{modified_attributes_list_list})
AdminConfig.save()
EOS
    debug "Running #{cmd}"
    result = wsadmin(file: cmd, user: resource[:user])
    debug result

    # Because this deals with global settings - we don't always have a node name to sync to
    # Do this, only when we have a node name passed as a param.
    sync_node unless resource[:node].nil?
  end
end
