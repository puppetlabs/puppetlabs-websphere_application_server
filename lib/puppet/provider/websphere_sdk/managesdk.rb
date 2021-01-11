# frozen_string_literal: true

require_relative '../websphere_helper'

Puppet::Type.type(:websphere_sdk).provide(:managesdk, parent: Puppet::Provider::Websphere_Helper) do
  desc 'managesdk provider for `websphere_sdk`'

  def managesdk(opts = {})
    command = build_command(opts)

    debug "Running as #{resource[:user]}: #{command}"

    result = nil
    Dir.chdir('/tmp') do
      result = Puppet::Util::Execution.execute(command, uid: resource[:user], combine: true)
    end

    unless %r{Successfully performed the requested managesdk task}.match?(result)
      raise Puppet::Error, "Websphere_sdk: Failure in command: #{command}. Output: #{result}"
    end

    debug "Result #{result}"

    result.chomp
  end

  def new_profile_default
    opts = {
      'getNewProfileDefault' => '',
    }

    result = managesdk(opts)[%r{.*: New profile creation SDK name: (.*).*$}, 1]

    debug "Current new_profile_default: #{result}"
    result.to_s.strip
  end

  def new_profile_default=(_value)
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

    result = managesdk(opts)[%r{.*: COMMAND_DEFAULT_SDK = (.*).*$}, 1]

    debug "Current command_default: #{result}"
    result.to_s.strip
  end

  def command_default=(_value)
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
      opts['listEnabledProfile'] = ''
      opts['profileName'] = resource[:profile]
    end

    result = managesdk(opts)

    result.each_line do |line|
      pattern = if resource[:server] && resource[:server] == 'all'.downcase
                  %r{(PROFILE_COMMAND_SDK = |SDK name: )}
                else
                  %r{(PROFILE_COMMAND_SDK = )}
                end

      ## If any of the returned versions don't match, return one of the non-compliant versions.
      next unless %r{#{pattern}}.match?(line)
      ## Even when modifying "all", nodeagent doesn't seem to update
      next if %r{nodeagent SDK name:}.match?(line)
      version = line[%r{#{pattern}(.*)(\s+)?$}, 2].strip
      debug "sdk Version #{version} found"
      unless version == resource[:sdkname]
        return version
      end
    end

    ## Return that we matched. Assuming none of
    ## the output versions above were incorrect.
    resource[:sdkname]
  end

  def sdkname=(_value)
    opts = {
      'sdkName' => resource[:sdkname],
    }
    if resource[:profile] == 'all'.downcase
      opts['enableProfileAll'] = ''
    else
      opts['enableProfile'] = ''
      opts['profileName'] = resource[:profile]
    end

    if resource[:server] && resource[:server] == 'all'.downcase
      opts['enableServers'] = ''
    end

    managesdk(opts)
  end

  private

  def build_command(options = {})
    command = "#{resource[:instance_base]}/bin/managesdk.sh "

    if resource[:username] && resource[:password]
      command << "-user '#{resource[:username]}' -password '#{resource[:password]}' "
    end

    options.each do |key, value|
      command << "-#{key} #{value} "
    end

    command.strip
  end
end
