require 'puppet/provider/websphere_helper'

Puppet::Type.type(:websphere_sdk).provide(:managesdk, :parent => Puppet::Provider::Websphere_Helper) do

  def managesdk(opts={})
    command = build_command(opts)

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
    opts = {
      'getNewProfileDefault' => '',
    }

    result = managesdk(opts)[/.*: New profile creation SDK name: (.*).*$/,1]

    self.debug "Current new_profile_default: #{result}"
    result.to_s.strip
  end

  def new_profile_default=(value)
    opts = {
      'setNewProfileDefault' => '',
      'sdkname'              => resource[:sdkname],
    }
    managesdk(opts)
  end

  def command_default
    opts = {
      'getCommandDefault' => '',
    }

    result = managesdk(opts)[/.*: COMMAND_DEFAULT_SDK = (.*).*$/,1]

    self.debug "Current command_default: #{result}"
    result.to_s.strip
  end

  def command_default=(value)
    opts = {
      'setCommandDefault' => '',
      'sdkname'           => resource[:sdkname],
    }
    managesdk(opts)
  end

  def sdkname
    opts = {}
    if resource[:profile] == 'all'.downcase
      opts['listEnabledProfileAll'] = ''
    else
      opts.merge!({
        'listEnabledProfile' => '',
        'profileName'        => resource[:profile],
      })
    end

    result = managesdk(opts)

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
    opts = {
      'sdkName' => resource[:sdkname],
    }
    if resource[:profile] == 'all'.downcase
      opts['enableProfileAll'] = ''
    else
      opts.merge!({
        'enableProfile' => '',
        'profileName'   => resource[:profile],
      })
    end

    if resource[:server] and resource[:server] == 'all'.downcase
      opts['enableServers'] = ''
    end

    managesdk(opts)
  end

  private

  def build_command(options={})
    command = "#{resource[:instance_base]}/bin/managesdk.sh "

    if resource[:username] and resource[:password]
      command << "-user '#{resource[:username]}' -password '#{resource[:password]}' "
    end

    options.each do |key, value|
      command << "-#{key} #{value} "
    end

    command.strip
  end
end
