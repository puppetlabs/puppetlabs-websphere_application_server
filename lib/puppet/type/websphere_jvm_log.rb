require 'pathname'

Puppet::Type.newtype(:websphere_jvm_log) do

  @doc = "This manages a WebSphere JVM Logging Properties"

  autorequire(:user) do
    self[:user] unless self[:user].to_s.nil?
  end

  newparam(:scope) do
    desc "The scope for the variable.
    Valid values: node or server
    "
    validate do |value|
      unless value =~ /^(node|server)$/
        raise ArgumentError, "Invalid scope #{value}: Must be node or server"
      end
    end
  end

  newproperty(:out_filename) do
    desc "The file System.out filename. Can include WebSphere variables"
  end

  newproperty(:err_filename) do
    desc "The file System.err filename. Can include WebSphere variables"
  end

  newproperty(:out_rollover_type) do
    desc "Type of log rotation to enable. SIZE TIME or BOTH"
    validate do |value|
      unless value =~ /^(SIZE|TIME|BOTH)$/
        raise ArgumentError, "Invalid out_rollover_type: #{value}. Must be SIZE, TIME, or BOTH"
      end
    end
  end

  newproperty(:err_rollover_type) do
    desc "Type of log rotation to enable. SIZE TIME or BOTH"
    validate do |value|
      unless value =~ /^(SIZE|TIME|BOTH)$/
        raise ArgumentError, "Invalid err_rollover_type: #{value}. Must be SIZE, TIME, or BOTH"
      end
    end
  end

  newproperty(:out_rollover_size) do
    desc "Filesize in MB for log rotation"
    validate do |value|
      unless value =~ /^\d+/
        raise ArgumentError, "Invalid out_rollover_size: #{value}. Must be digit."
      end
    end
  end

  newproperty(:err_rollover_size) do
    desc "Filesize in MB for log rotation"
    validate do |value|
      unless value =~ /^\d+/
        raise ArgumentError, "Invalid err_rollover_size: #{value}. Must be digit."
      end
    end
  end

  newproperty(:out_maxnum) do
    desc "Maximum number of historical log files. 1-200"
    validate do |value|
      unless value =~ /^\d+/
        raise ArgumentError, "Invalid out_maxnum: #{value}. Must be digit 1-200."
      end

      unless value.to_i < 201 or value.to_i > 0
        raise ArgumentError, "out_maxnum must be 1-200"
      end
    end
  end

  newproperty(:err_maxnum) do
    desc "Maximum number of historical log files. 1-200"
    validate do |value|
      unless value =~ /^\d+/
        raise ArgumentError, "Invalid err_maxnum: #{value}. Must be digit 1-200."
      end

      unless value.to_i < 201 or value.to_i > 0
        raise ArgumentError, "err_maxnum must be 1-200"
      end
    end
  end

  newproperty(:out_start_hour) do
    desc "Start time for time-based log rotation. 1-24"
    validate do |value|
      unless value =~ /^\d+/
        raise ArgumentError, "Invalid out_start_hour: #{value}. Must be digit 1-24."
      end

      unless value.to_i < 25 or value.to_i > 0
        raise ArgumentError, "out_start_hour must be 1-24"
      end
    end
  end

  newproperty(:err_start_hour) do
    desc "Start time for time-based log rotation. 1-24"
    validate do |value|
      unless value =~ /^\d+/
        raise ArgumentError, "Invalid err_start_hour: #{value}. Must be digit 1-24."
      end

      unless value.to_i < 25 or value.to_i > 0
        raise ArgumentError, "err_start_hour must be 1-24"
      end
    end
  end

  newproperty(:out_rollover_period) do
    desc "Time period (log repeat time) for time-based log rotation. 1-24"
    validate do |value|
      unless value =~ /^\d+/
        raise ArgumentError, "Invalid out_rollover_period: #{value}. Must be digit 1-24."
      end

      unless value.to_i < 25 or value.to_i > 0
        raise ArgumentError, "out_rollover_period must be 1-24"
      end
    end
  end

  newproperty(:err_rollover_period) do
    desc "Time period (log repeat time) for time-based log rotation. 1-24"
    validate do |value|
      unless value =~ /^\d+/
        raise ArgumentError, "Invalid err_rollover_period: #{value}. Must be digit 1-24."
      end

      unless value.to_i < 25 or value.to_i > 0
        raise ArgumentError, "err_rollover_period must be 1-24"
      end
    end
  end

  newparam(:server) do
    desc "The server in the scope for this variable"
    validate do |value|
      if value.nil? and self[:scope] == 'server'
        raise ArgumentError, 'server is required when scope is server'
      end
      unless value =~ /^[-0-9A-Za-z._]+$/
        raise ArgumentError, "Invalid server #{value}"
      end
    end
  end

  newparam(:cell) do
    validate do |value|
      if value.nil? and self[:scope] =~ /(server|cell|node|cluster)/
        raise ArgumentError, 'cell is required when scope is cell or server'
      end
      unless value =~ /^[-0-9A-Za-z._]+$/
        raise ArgumentError, "Invalid cell: #{value}"
      end
    end
  end

  newparam(:node) do
    validate do |value|
      if value.nil? and self[:scope] =~ /(server|cell|node)/
        raise ArgumentError, 'node is required when scope is server, cell, or node'
      end
      unless value =~ /^[-0-9A-Za-z._]+$/
        raise ArgumentError, "Invalid node: #{value}"
      end
    end
  end

  newparam(:profile) do
    desc <<-EOT
    The profile to run 'wsadmin' under. This can be an appserver profile or
    a DMGR profile as long as it can run 'wsadmin'.

    Examples: dmgrProfile01, PROFILE_APP_001
    EOT
    validate do |value|
      if value.nil?
        raise ArgumentError, 'profile is required'
      end
      unless value =~ /^[-0-9A-Za-z._]+$/
        raise ArgumentError, "Invalid profile #{value}"
      end
    end
  end

  newparam(:dmgr_profile) do
    defaultto { @resource[:profile] }
    desc <<-EOT
    The profile to run 'wsadmin' under. This can be an appserver profile or
    a DMGR profile as long as it can run 'wsadmin'.

    Examples: dmgrProfile01, PROFILE_APP_001
    EOT
    validate do |value|
      if value.nil?
        raise ArgumentError, 'profile is required'
      end
      unless value =~ /^[-0-9A-Za-z._]+$/
        raise ArgumentError, "Invalid profile #{value}"
      end
    end
  end

  newparam(:name) do
    isnamevar
    desc "The name of the resource"
  end

  newparam(:profile_base) do
    desc "The base directory that profiles are stored.
      Example: /opt/IBM/WebSphere/AppServer/profiles"

      validate do |value|
        unless Pathname.new(value).absolute?
          raise ArgumentError, "Invalid profile_base #{value}"
        end
      end
  end

  newparam(:user) do
    defaultto 'root'
    desc "The user to run 'wsadmin' with"
    validate do |value|
      unless value =~ /^[-0-9A-Za-z._]+$/
        raise ArgumentError, "Invalid user #{value}"
      end
    end
  end

  newparam(:wsadmin_user) do
    desc "The username for wsadmin authentication"
  end

  newparam(:wsadmin_pass) do
    desc "The password for wsadmin authentication"
  end
end
