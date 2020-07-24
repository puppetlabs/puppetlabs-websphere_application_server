# Provider for managing WebSphere clusters via 'wsadmin'
#
# This thing needs some love - some Ruby refinement.
# Basically, the user-provided attribute values determine what command to use
# via the profile_base.  The 'wsadmin' command to use depends on what profile
# we're working with, and a system can have several profiles.
#
# This provider should just handle the creating and removal of clusters.
require_relative '../websphere_helper'

Puppet::Type.type(:websphere_cluster).provide(:wsadmin, parent: Puppet::Provider::Websphere_Helper) do
  desc 'wsadmin provider for `websphere_cluster`'

  def exists?
    cluster_xml = resource[:profile_base] + '/' + resource[:dmgr_profile] + '/config/cells/*/clusters/' + resource[:name] + '/cluster.xml'

    Dir.glob(cluster_xml) do |file_name|
      xml_data = File.open(file_name)
      doc = REXML::Document.new(xml_data)

      value = doc.root.attributes['name']
      debug "Exists? #{resource[:name]} : #{value}"

      if value.to_s == resource[:name]
        return true
      end
    end
    false
  end

  def create
    # Need some error handling here, I suppose. Unfortunately, wsadmin always
    # exits 0
    cmd = "\"AdminTask.createCluster('[-clusterConfig [-clusterName #{resource[:name]}]]')\""

    debug "wsadmin: Creating cluster via #{cmd}"

    result = wsadmin(command: cmd, user: resource[:user])

    debug result
  end

  def destroy
    # Need some error handling here, I suppose. Unfortunately, wsadmin always
    # exits 0
    # We also might need to handle stopping the cluster first.
    cmd = "\"AdminTask.deleteCluster('[-clusterName "
    cmd += resource[:name]
    cmd += "]')\""

    debug "Deleting cluster via #{wascmd}#{cmd}"

    result = wsadmin(command: cmd, user: resource[:user])

    debug result
  end

  def flush; end
end
