# Provider for federating websphere nodes to a cell
#
# This is not the most robust of things - but it's hard to predict what
# messages or exit code (if any) the IBM tools will provide.
#
# This will search for a 'data' file in the profile dir that contains
# information for federating a node (port, hostname).  It's assumed that this
# file will be exported by the dmgr host and collected on the server
# that's declaring this resource.
# Optionally, a port and host can be passed as parameters to this resource.
#
require 'yaml'

Puppet::Type.type(:websphere_federate).provide(:wsadmin) do

  def exists?
    path = "#{resource[:profile_base]}/#{resource[:profile]}/config/cells/#{resource[:cell]}/nodes/#{resource[:node]}/servers"
    if File.exists?(path)
      self.debug "Already federated: " + path + " exists"
      return true
    end
    false
  end

  def create

    data_file = "#{resource[:profile_base]}/#{resource[:profile]}"  + '/dmgr_' + resource[:dmgr_host].downcase + '_' + resource[:cell].downcase + '.yaml'

    if File.exists?(data_file)
      yaml = YAML.load_file(data_file)

      soap_port = yaml['dmgr_soap']
      dmgr_host = yaml['dmgr_fqdn']

      self.debug "#{data_file} found."
      self.debug "soap_port: #{soap_port} / dmgr_host: #{dmgr_host}"
    else
      self.debug "#{data_file} does not exist."
      soap_port = resource[:soap_port]
      dmgr_host = resource[:dmgr_host]
    end

    if soap_port and dmgr_host
      cmd = resource[:profile_base] + '/' + resource[:profile] + '/bin/'
      cmd += "addNode.sh #{dmgr_host} #{soap_port}"
      cmd += ' -conntype SOAP -noagent'

      if resource[:username] and resource[:password]
        cmd += " -username '#{resource[:username]}' -password '#{resource[:password]}'"
      end

      if resource[:options]
        cmd += " #{resource[:options]}"
      end

      self.debug "as user #{resource[:user]} #{cmd}"

      result = nil
      Dir.chdir('/tmp') do
        result = Puppet::Util::Execution.execute(cmd, :uid => resource[:user])
      end

      self.debug "result: #{result}"
      unless result =~ /Node .* has been successfully federated/
        raise Puppet::Error, "#{resource[:node]} may not have been successful federating. Run with --debug for details."
        false
      end

    else
      raise Puppet::Error, "Websphere_federate[#{resource[:name]}]: soap_port "\
                   + "and dmgr_host not present and data file not "\
                   + "available. Has the DMGR node ran Puppet and exported "\
                   + "its data? Not federating."
    end
  end

  def destroy
    cmd = resource[:profile_base] + '/' + resource[:profile] + '/bin/'
    cmd += "removeNode.sh"

    if resource[:username] and resource[:password]
      cmd += " -username '#{resource[:username]}' -password '#{resource[:password]}'"
    end

    if resource[:options]
      cmd += " #{resource[:options]}"
    end

    self.debug "Executing #{cmd}"

    result = nil
    Dir.chdir('/tmp') do
      result = Puppet::Util::Execution.execute(cmd, :uid => resource[:user])
    end

    self.debug "result: #{result}"
    unless result =~ /Removal of node .* is complete/
      raise Puppet::Error, "#{resource[:node]} may not have been successful unfederating. Run with --debug for details."
      false
    end

  end

end
