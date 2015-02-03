require 'puppet/provider/websphere_helper'

Puppet::Type.type(:websphere_sdk).provide(:managesdk, :parent => Puppet::Provider::Websphere_Helper) do

  def managesdk(args={})
    command = resource[:instance_base]
    command += '/bin/managesdk.sh '

    if resource[:username] and resource[:password]
      command += '-user "' + resource[:username] + '" -password "' + resource[:password] + '" '
    end

    if args[:command]
      command += args[:command]
    end

    self.debug "Running as #{resource[:user]}: #{command}"

    result = nil
    Dir.chdir('/tmp') do
      result = Puppet::Util::Execution.execute(command, :uid => resource[:user], :combine => true)
    end

    unless result =~ /Successfully performed the requested managesdk task/
      raise Puppet::Error, "Websphere_sdk: Failure in command: #{command}. Output: #{result}"
    end

    self.debug "Result #{result}"

    result.chomp
  end

  def new_profile_default
    command = '-getNewProfileDefault'

    result = managesdk(:command => command)[/.*: New profile creation SDK name: (.*).*$/,1]

    self.debug "Current new_profile_default: #{result}"
    result.to_s.strip
  end

  def new_profile_default=(value)
    command = '-setNewProfileDefault -sdkname ' + resource[:sdkname].to_s
    managesdk(:command => command)
  end

  def command_default
    command = '-getCommandDefault'

    result = managesdk(:command => command)[/.*: COMMAND_DEFAULT_SDK = (.*).*$/,1]

    self.debug "Current command_default: #{result}"
    result.to_s.strip
  end

  def command_default=(value)
    command = '-setCommandDefault -sdkname ' + resource[:sdkname].to_s
    managesdk(:command => command)
  end

  def sdkname

    if resource[:profile] == 'all'.downcase
      command = '-listEnabledProfileAll'
    else
      command = '-listEnabledProfile -profileName ' + resource[:profile]
    end

    result = managesdk(:command => command)

    result.each_line do |line|
      if resource[:server] and resource[:server] == 'all'.downcase
        pattern = /(PROFILE_COMMAND_SDK = |SDK name: )/
      else
        pattern = /(PROFILE_COMMAND_SDK = )/
      end

      ## This is garbage.  If any of the returned versions don't match, just
      ## return one of the non-compliant versions.
      if line =~ /#{pattern}/
        ## IBM... Even when modifying "all", nodeagent doesn't seem to update
        next if line =~ /nodeagent SDK name:/
        version = line[/#{pattern}(.*)(\s+)?$/,2].strip
        self.debug "sdk Version #{version} found"
        unless version == resource[:sdkname]
          return version
        end
      end

    end

    ## This is, too. Otherwise, just return that we matched. Assuming none of
    ## the output versions above were incorrect.
    return resource[:sdkname]

  end

  def sdkname=(value)

    if resource[:profile] == 'all'.downcase
      modifycmd = '-enableProfileAll'
    else
      modifycmd = '-enableProfile -profileName ' + resource[:profile]
    end

    modifycmd += ' -sdkName ' + resource[:sdkname].to_s
    if resource[:server] and resource[:server] == 'all'.downcase
      modifycmd += ' -enableServers'
    end
    managesdk(:command => modifycmd)

  end

  def flush
  end

end
