# frozen_string_literal: true

require 'rexml/document'
require 'tempfile'

# Common functionality for our websphere cluster providers.
# The methods here are generic enough to be used in multiple providers.
class Puppet::Provider::Websphere_Helper < Puppet::Provider # rubocop:disable Style/ClassAndModuleCamelCase
  ## Build the base 'wsadmin' command that we'll use to make changes.  This
  ## command is derived from whatever the 'profile_base' is (since wsadmin is
  ## profile-specific), the name of the profile, and credentials, if provided.
  ## Can we use the 'commands' method for this?
  def wascmd(file = nil)
    wsadmin_failure_message = 'Unable to find wsadmin.sh.'

    if resource[:profile]
      wsadmin_file = "#{resource[:profile_base]}/#{resource[:profile]}/bin/wsadmin.sh"
      wsadmin_failure_message += " File doesn't exist at '#{wsadmin_file}'."
    end

    if resource[:profile].nil? || !File.exist?(wsadmin_file)
      wsadmin_file = "#{resource[:profile_base]}/#{resource[:dmgr_profile]}/bin/wsadmin.sh"
      wsadmin_failure_message += " File doesn't exist at '#{wsadmin_file}'."
    end

    # File.exists? is a double check if resource[:profile] is set but at
    # least you will know for sure
    raise Puppet::Error, "#{wsadmin_failure_message}. Please ensure the script exists at a proper location." unless File.exist?(wsadmin_file)

    wsadmin_cmd = "#{wsadmin_file} -lang jython"

    if resource[:wsadmin_user] && resource[:wsadmin_pass]
      wsadmin_cmd << " -username '#{resource[:wsadmin_user]}'"
      wsadmin_cmd << " -password '#{resource[:wsadmin_pass]}'"
    end

    wsadmin_cmd << if file
                     " -f #{file} "
                   else
                     ' -c '
                   end

    wsadmin_cmd
  end

  ## Method to make changes to the WAS configuration. Pass:
  ## :command => 'some jython'
  ##   The value will be sent to 'wsadmin' with the '-c' argument - evaluating
  ##   the code on the command line.
  ## :file => 'some jython'
  ##   The value will be written to a temporary file and read in by wsadmin
  ##   using the '-f' argument.  This is for more complicated jython that
  ##   doesn't take kindly to being fed in on the command-line.
  def wsadmin(args = {})
    if args[:file]
      cmdfile = Tempfile.new('wascmd_')

      ## File needs to be readable by the specified user.
      cmdfile.chmod(0o644)
      cmdfile.write(args[:file])
      cmdfile.rewind
      modify = wascmd(cmdfile.path)
    else
      modify = wascmd + args[:command]
    end

    result = nil

    begin
      debug "Executing as user #{args[:user]}: #{modify}"
      Dir.chdir('/tmp') do
        result = Puppet::Util::Execution.execute(
          modify,
          failonfail: args[:failonfail] != false,
          uid: args[:user] || 'root',
          combine: true,
        )
      end

      result
    rescue StandardError => e
      raise Puppet::Error, "Command failed for #{resource[:name]}: #{e}" if args[:failonfail]
      Puppet.warning("Command failed for #{resource[:name]}: #{e}")
    ensure
      if args[:file]
        cmdfile.close
        cmdfile.unlink
      end
    end
  end

  ## Helper method to query the 'server.xml' file for an attribute.
  ## value.  Ideally, we could have this query any arbitrary xml value with
  ## any depth.  It's rigid and fixed at three levels deep for now.
  def get_xml_val(section, element, attribute, server_xml = nil)
    unless server_xml
      serverxml_failure_message = 'Unable to find server xml file.'

      if resource[:profile]
        server_xml = resource[:profile_base] + '/' \
          + resource[:profile] + '/config/cells/' \
          + resource[:cell] + '/nodes/' + resource[:node_name] \
          + '/servers/' + resource[:server] + '/server.xml'
        serverxml_failure_message += " File doesn't exist at '#{server_xml}'."
      end

      if resource[:profile].nil? || !File.exist?(server_xml)
        server_xml = resource[:profile_base] + '/' \
          + resource[:dmgr_profile] + '/config/cells/' \
          + resource[:cell] + '/nodes/' + resource[:node_name] \
          + '/servers/' + resource[:server] + '/server.xml'
        serverxml_failure_message += " File doesn't exist at '#{server_xml}'."
      end

      # File.exists? is a double check if resource[:profile] is set
      raise Puppet::Error, "#{serverxml_failure_message}. Please ensure the script exists at a proper location." unless File.exist?(server_xml)
    end

    unless File.exist?(server_xml)
      raise Puppet::Error, "#{resource[:name]}: "\
        + "Unable to open server.xml at #{server_xml}. Make sure the profile "\
        + 'exists, the node has been federated, a corresponding app instance '\
        + 'exists, and the names are correct. Hint:  The DMGR may need to '\
        + 'Puppet.'
    end

    xml_data = File.open(server_xml)
    doc = REXML::Document.new(xml_data)
    value = doc.root.elements[section].elements[element].attributes[attribute]

    debug "#{server_xml}/#{element}:#{attribute}: #{value}"

    false unless value
    value.to_s
  end

  ## This synchronizes the app node(s) with the dmgr
  def sync_node
    sync_status = "\"the_id = AdminControl.completeObjectName('type=NodeSync,"
    sync_status << "node=#{resource[:node_name]},*');"
    sync_status << "AdminControl.invoke(the_id, 'isNodeSynchronized')\""

    status = wsadmin(
      command: sync_status,
      user: resource[:user],
      failonfail: false,
    )
    debug "Sync status #{resource[:node_name]}: #{status}"

    return if status.include?("'true'")
    if status =~ %r{Error found in String ""; cannot create ObjectName}
      msg = <<-EOT
      Attempt to synchronize node failed because the node service likely
      isn't running or reachable.  A message about "cannot create ObjectName
      often indicates this.  Ensure that the NODE service is running.
      If the node service isn't running, synchronization will happen once
      it's started.  Node: #{resource[:node_name]}
      "
      EOT
      debug msg
    else
      sync = "\"the_id = AdminControl.completeObjectName('type=NodeSync,"
      sync << "node=#{resource[:node_name]},*');"
      sync << "AdminControl.invoke(the_id, 'sync')\""

      result = wsadmin(
        command: sync,
        user: resource[:user],
        failonfail: false,
      )
      debug "Sync node #{resource[:node_name]}: #{result}"
      result
    end
  end

  def restart_server
    if resource[:server]
      cmd = <<-EOT.unindent
      ns = AdminControl.queryNames('WebSphere:*,type=Server,name=#{resource[:server]}').splitlines()
      server = ns[0]
      AdminControl.invoke(server, 'restart')
      EOT
      debug "Restarting #{resource[:node_name]} #{resource[:server]} with #{cmd}"
      result = wsadmin(file: cmd, user: resource[:user], failonfail: false)
      debug "Result: #{result}"
    end

    return unless resource[:node_name]
    cmd = "\"na = AdminControl.queryNames('type=NodeAgent,node=#{resource[:node_name]},*');"
    cmd << "AdminControl.invoke(na,'restart','true true')\""

    debug "Restarting node: #{resource[:node_name]} with #{cmd}"
    result = wsadmin(command: cmd, user: resource[:user], failonfail: false)
    debug "Result: #{result}"
  end

  ## We want to make sure we sync the app node with the dmgr when things
  ## change.  This happens automatically anyway, but with a delay.
  def flush
    sync_node
  end
end

# Provide ability to remove indentation from strings, for the purpose of
# left justifying heredoc blocks.
class String
  def unindent
    gsub(%r{^#{scan(%r{^\s*}).min_by { |l| l.length }}}, '')
  end
end
