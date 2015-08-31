require 'pathname'

Puppet::Type.newtype(:websphere_jvm_log) do

  @doc = "This manages a WebSphere JVM Logging Properties"

  autorequire(:user) do
    self[:user]
  end

  validate do
    raise ArgumentError, 'scope is required' if self[:scope].nil?
    raise ArgumentError, 'server is required' if self[:server].nil? and self[:scope].to_s =~ /^server$/i
    raise ArgumentError, 'cell is required' if self[:cell].nil?
    raise ArgumentError, 'node is required' if self[:node].nil?
    raise ArgumentError, 'profile is required' if self[:profile].nil?
  end

    def self.title_patterns
      identity = lambda {|x| x}
      [
        [
        /^(.*):(.*):(.*):(.*)$/,
          [
            [:cell, identity ],
            [:node, identity ],
            [:scope, identity ],
            [:server, identity ]
          ]
        ],
        [
        /^(.*):(.*):(.*)$/,
          [
            [:cell, identity ],
            [:node, identity ],
            [:scope, identity ],
          ]
        ],
        [
        /^(.*):(.*)$/,
          [
            [:cell, identity ],
            [:node, identity ]
          ]
        ],
        [
        /^(.*)$/,
          [
            [:cell, identity ]
          ]
        ]
      ]
    end

  newparam(:scope) do
    desc "The scope for the variable. Valid values: node or server"
    newvalues(:node, :NODE, :server, :SERVER)
  end

  newproperty(:out_filename) do
    desc "The file System.out filename. Can include WebSphere variables"
  end

  newproperty(:err_filename) do
    desc "The file System.err filename. Can include WebSphere variables"
  end

  newproperty(:out_rollover_type) do
    desc "Type of log rotation to enable. Must be size, time, or both"
    newvalues(:size, :SIZE, :time, :TIME, :both, :BOTH)
    munge do |value|
      value.upcase
    end
  end

  newproperty(:err_rollover_type) do
    desc "Type of log rotation to enable. Must be size, time, or both"
    newvalues(:size, :SIZE, :time, :TIME, :both, :BOTH)
    munge do |value|
      value.upcase
    end
  end

  newproperty(:out_rollover_size) do
    desc "Filesize in MB for log rotation"
    validate do |value|
      unless value.to_s =~ /^\d+/
        raise ArgumentError, "Invalid out_rollover_size: #{value}. Must be integer."
      end
    end
  end

  newproperty(:err_rollover_size) do
    desc "Filesize in MB for log rotation"
    validate do |value|
      unless value.to_s =~ /^\d+/
        raise ArgumentError, "Invalid err_rollover_size: #{value}. Must be integer."
      end
    end
  end

  newproperty(:out_maxnum) do
    desc "Maximum number of historical log files. 1-200"
    validate do |value|
      unless value.to_s =~ /^\d+/ and value.to_i.between?(1, 200)
        raise ArgumentError, "Invalid out_maxnum: #{value}. Must be an integer between 1-200."
      end
    end
  end

  newproperty(:err_maxnum) do
    desc "Maximum number of historical log files. 1-200"
    validate do |value|
      unless value.to_s =~ /^\d+/ and value.to_i.between?(1, 200)
        raise ArgumentError, "Invalid err_maxnum: #{value}. Must be an integer between 1-200."
      end
    end
  end

  newproperty(:out_start_hour) do
    desc "Start time for time-based log rotation. 1-24"
    validate do |value|
      unless value.to_s =~ /^\d+/ and value.to_i.between?(1, 24)
        raise ArgumentError, "Invalid out_start_hour: #{value}. Must be an integer between 1-24."
      end
    end
  end

  newproperty(:err_start_hour) do
    desc "Start time for time-based log rotation. 1-24"
    validate do |value|
      unless value.to_s =~ /^\d+/ and value.to_i.between?(1, 24)
        raise ArgumentError, "Invalid err_start_hour: #{value}. Must be an integer between 1-24."
      end
    end
  end

  newproperty(:out_rollover_period) do
    desc "Time period (log repeat time) for time-based log rotation. 1-24"
    validate do |value|
      unless value.to_s =~ /^\d+/ and value.to_i.between?(1, 24)
        raise ArgumentError, "Invalid out_rollover_period: #{value}. Must be an integer between 1-24."
      end
    end
  end

  newproperty(:err_rollover_period) do
    desc "Time period (log repeat time) for time-based log rotation. 1-24"
    validate do |value|
      unless value.to_s =~ /^\d+/ and value.to_i.between?(1, 24)
        raise ArgumentError, "Invalid err_rollover_period: #{value}. Must be an integer between 1-24."
      end
    end
  end

  newparam(:server) do
    isnamevar

    desc "The server in the scope for this variable"
    validate do |value|
      unless value =~ /^[-0-9A-Za-z._]+$/
        raise ArgumentError, "Invalid server #{value}"
      end
    end
  end

  newparam(:cell) do
    isnamevar

    validate do |value|
      unless value =~ /^[-0-9A-Za-z._]+$/
        raise ArgumentError, "Invalid cell: #{value}"
      end
    end
  end

  newparam(:node) do
    isnamevar

    validate do |value|
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
      unless value =~ /^[-0-9A-Za-z._]+$/
        raise ArgumentError, "Invalid profile #{value}"
      end
    end
  end

  newparam(:dmgr_profile) do
    desc <<-EOT
    The profile to run 'wsadmin' under. This can be an appserver profile or
    a DMGR profile as long as it can run 'wsadmin'.

    Examples: dmgrProfile01, PROFILE_APP_001
    EOT
    defaultto { @resource[:profile] }
    validate do |value|
      unless value =~ /^[-0-9A-Za-z._]+$/
        raise ArgumentError, "Invalid dmgr_profile #{value}"
      end
    end
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
