require_relative '../websphere_helper'
Puppet::Type.type(:websphere_node).provide(:wsadmin, parent: Puppet::Provider::Websphere_Helper) do
  desc 'wsadmin provider for `websphere_node`'

  def create
    cmd = "\"AdminTask.createUnmanagedNode('[-nodeName #{resource[:node_name]} "
    cmd += "-hostName #{resource[:hostname]} -nodeOperatingSystem "
    cmd += "#{resource[:os]}]')\""

    debug "Running #{cmd}"
    result = wsadmin(command: cmd, user: resource[:user])
    debug result
  end

  def exists?
    xml_file = resource[:profile_base] + '/' + resource[:dmgr_profile] + '/config/cells/' + resource[:cell] + '/nodes/' + resource[:node_name] + '/node.xml'

    unless File.exist?(xml_file)
      debug "File does not exist! #{xml_file}"
      return false
    end
    doc = REXML::Document.new(File.open(xml_file))
    path = REXML::XPath.first(doc, "//topology.node:Node[@name='#{resource[:node_name]}']")
    value = REXML::XPath.first(path, '@name') if path

    debug "Exists? #{resource[:node_name]} : #{value}"

    unless value
      debug "#{resource[:node_name]} does not exist"
      return false
    end
    true
  end

  def destroy
    cmd = "\"AdminTask.removeUnmanagedNode('[-nodeName #{resource[:node_name]}]')\""

    debug "Running #{cmd}"
    result = wsadmin(command: cmd, user: resource[:user])
    debug result
  end

  def flush
    # do nothing
  end
end
