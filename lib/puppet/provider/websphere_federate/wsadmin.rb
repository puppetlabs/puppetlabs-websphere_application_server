# frozen_string_literal: true

require 'yaml'

Puppet::Type.type(:websphere_federate).provide(:wsadmin) do
  desc <<-DESC
    Provider for `websphere_federate`

    This is not the most robust of things - but it's hard to predict what
    messages or exit code (if any) the IBM tools will provide.

    This will search for a 'data' file in the profile dir that contains
    information for federating a node (port, hostname).  It's assumed that this
    file will be exported by the dmgr host and collected on the server
    that's declaring this resource.
    Optionally, a port and host can be passed as parameters to this resource.

    DESC
  def exists?
    path = "#{resource[:profile_base]}/#{resource[:profile]}/config/cells/#{resource[:cell]}/nodes/#{resource[:node_name]}/servers"
    if File.exist?(path)
      debug 'Already federated: ' + path + ' exists'
      return true
    end
    false
  end

  def create
    data_file = "#{resource[:profile_base]}/#{resource[:profile]}" + '/dmgr_' + resource[:dmgr_host].downcase + '_' + resource[:cell].downcase + '.yaml'

    if File.exist?(data_file)
      yaml = YAML.load_file(data_file)

      soap_port = yaml['dmgr_soap']
      dmgr_host = yaml['dmgr_fqdn']

      debug "#{data_file} found."
      debug "soap_port: #{soap_port} / dmgr_host: #{dmgr_host}"
    else
      debug "#{data_file} does not exist."
      soap_port = resource[:soap_port]
      dmgr_host = resource[:dmgr_host]
    end

    if soap_port && dmgr_host
      cmd = resource[:profile_base] + '/' + resource[:profile] + '/bin/'
      cmd += "addNode.sh #{dmgr_host} #{soap_port}"
      cmd += ' -conntype SOAP -noagent'

      if resource[:username] && resource[:password]
        cmd += " -username '#{resource[:username]}' -password '#{resource[:password]}'"
      end

      if resource[:options]
        cmd += " #{resource[:options]}"
      end

      debug "as user #{resource[:user]} #{cmd}"

      result = nil
      Dir.chdir('/tmp') do
        result = Puppet::Util::Execution.execute(cmd, uid: resource[:user])
      end

      debug "result: #{result}"
      # Validate the result, regex should account for whitespace and new line inconsistencies in wsadmin.
      unless %r{Node\s*.*\s*has\s*been\s*successfully\s*federated}.match?(result.delete("\n"))
        raise Puppet::Error, "#{resource[:node_name]} may not have been successful federating. Run with --debug for details."
      end

    else
      raise Puppet::Error, "Websphere_federate[#{resource[:name]}]: soap_port "\
                   + 'and dmgr_host not present and data file not '\
                   + 'available. Has the DMGR node ran Puppet and exported '\
                   + 'its data? Not federating.'
    end
  end

  def destroy
    cmd = resource[:profile_base] + '/' + resource[:profile] + '/bin/'
    cmd += 'removeNode.sh'

    if resource[:username] && resource[:password]
      cmd += " -username '#{resource[:username]}' -password '#{resource[:password]}'"
    end

    if resource[:options]
      cmd += " #{resource[:options]}"
    end

    debug "Executing #{cmd}"

    result = nil
    Dir.chdir('/tmp') do
      result = Puppet::Util::Execution.execute(cmd, uid: resource[:user])
    end

    debug "result: #{result}"

    raise Puppet::Error, "#{resource[:node_name]} may not have been successful unfederating. Run with --debug for details." unless %r{Removal of node .* is complete}.match?(result)
  end
end
