# Type for managing websphere cluster members
# TODO:
#   - Parameter validation
#   - Sane defaults for parameters
#   - Other things?
#   - Better documentation for params?
#
Puppet::Type.newtype(:websphere_cluster_member_service) do

  @doc = "Manages the a WebSphere cluster member's service."

  autorequire(:websphere_cluster) do
    self[:name]
  end

  autorequire(:websphere_cluster_member) do
    self[:name]
  end

  ensurable do
    desc <<-EOT
      Valid values: `running` or `stopped`

      Defaults to `running`.  Specifies whether the service should be running or not.
    EOT

    newvalue(:stopped, :event => :service_stopped) do
      provider.stop
    end

    newvalue(:running, :event => :service_started, :invalidate_refreshes => true) do
      provider.start
    end

    aliasvalue(:false, :stopped)
    aliasvalue(:true, :running)

    def retrieve
      provider.status
    end
  end

  # Basically just a synonym for restarting.  Used to respond
  # to events.
  def refresh
    # Only restart if we're actually running
    if (@parameters[:ensure] || newattr(:ensure)).retrieve == :running
      provider.restart
    else
      debug "Skipping restart; service is not running"
    end
  end

  newparam(:cell) do
    desc "The name of the cell the cluster member belongs to"
    validate do |value|
      unless value =~ /^[-0-9A-Za-z._]+$/
        fail("Invalid cell #{value}")
      end
    end
  end

  newparam(:cluster) do
    desc "Required. The cluster that the cluster member belongs to."
    validate do |value|
      unless value =~ /^[-0-9A-Za-z._]+$/
        fail("Invalid cluster #{value}")
      end
    end
  end

  newparam(:dmgr_profile) do
    desc "The name of the DMGR profile to manage. E.g. PROFILE_DMGR_01"
    validate do |value|
      unless value =~ /^[-0-9A-Za-z._]+$/
        fail("Invalid dmgr_profile #{value}")
      end
    end
  end

  newparam(:name) do
    desc 'The name of the cluster member that this service belongs to.'
    isnamevar
    validate do |value|
      unless value =~ /^[-0-9A-Za-z._]+$/
        fail("Invalid name #{value}")
      end
    end
  end

  newparam(:node) do
    desc <<-EOT
      Required. The name of the _node_ that this cluster member is on. Refer to
      the `websphere_node` type for managing the creation of nodes.
    EOT
    validate do |value|
      unless value =~ /^[-0-9A-Za-z._]+$/
        fail("Invalid node #{value}")
      end
    end
  end

  newparam(:profile_base) do
    desc "The absolute path to the profile base directory. E.g. /opt/IBM/WebSphere/AppServer/profiles"
    validate do |value|
      fail("Invalid profile_base #{value}") unless Pathname.new(value).absolute?
    end
  end

  newparam(:dmgr_host) do
    desc <<-EOT
      The DMGR host to add this cluster member service to.

      This is required if you're exporting the cluster member for a DMGR to
      collect.  Otherwise, it's optional.
    EOT
  end

  newparam(:user) do
    defaultto 'root'
    desc "Specifies the user to execute wsadmin as"
  end

  newparam(:wsadmin_user) do
    desc "Specifies the username for using 'wsadmin'"
  end

  newparam(:wsadmin_pass) do
    desc "Specifies the password for using 'wsadmin'"
  end

end
