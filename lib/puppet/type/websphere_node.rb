require 'pathname'

Puppet::Type.newtype(:websphere_node) do

  @doc = <<-EOT
    Manages the an "unmanaged" WebSphere node in a cell.  For example, adding an
    IHS server to a cell.

    In `wsadmin` terms using _jython_, this basically translates to the
    `AdminTask.createUnmanagedNode` task.

    #### Example

    websphere_node { 'IHS Server':
      node         => 'ihsServer01',
      os           => 'linux',
      hostname     => 'ihs01.example.com',
      cell         => 'CELL_01',
      dmgr_profile => 'PROFILE_DMGR_01',
      profile_base => '/opt/IBM/WebSphere/AppServer/profiles',
      user         => 'webadmins',
    }

    Exported resource example

    An IHS server can export a resource:

    @@websphere_node { $::fqdn:
      node     => $::fqdn,
      os       => 'linux',
      hostname => $::fqdn,
      cell     => 'CELL_01',

    A DMGR can collect it and append its profile information to it:

    Websphere_node <<| cell == 'CELL_01' |>> {
      dmgr_profile => 'PROFILE_DMGR_01',
      profile_base => '/opt/IBM/Websphere/AppServer/profiles',
      user         => 'webadmins',
    }
  EOT

  ensurable

  newparam(:dmgr_profile) do
    desc "The dmgr profile that this node should be managed under
      Example: dmgrProfile01"

    validate do |value|
      unless value =~ /^[-0-9A-Za-z._]+$/
        fail("Invalid dmgr_profile #{value}")
      end
    end
  end

  ## We could make this a property later, but we'll need to ask for more
  ## parameters to do so.
  newparam(:hostname) do
    desc "The hostname for the unmanaged node."
    validate do |value|
      unless value
        fail("You must provide a hostname")
      end
    end
  end

  newparam(:node) do
    isnamevar
    desc <<-EOT
      The name of the node to manage.  Defaults to the `name` parameter value.
    EOT

    validate do |value|
      unless value =~ /^[-0-9A-Za-z._]+$/
        fail("Invalid node name: #{value}")
      end
    end
  end

  newparam(:os) do
    desc <<-EOT
      The node's operating system.
      Defaults to 'linux'
    EOT
    defaultto 'linux'
    validate do |value|
      unless value =~ /(linux|aix)/
        fail("OS #{value} not supported. Must be 'linux' or 'aix'")
      end
    end
    munge do |value|
      value.downcase
    end
  end

  newparam(:cell) do
    desc <<-EOT
      The cell that this node should be a part of.

      The purpose of this parameter is so that a DMGR instance can determine
      which nodes belong to it when collecting exported resources.
    EOT
  end

  newparam(:profile_base) do
    desc <<-EOT
      The base directory that profiles are stored.

      Example: /opt/IBM/WebSphere/AppServer/profiles"
    EOT

    validate do |value|
      fail("Invalid profile_base #{value}") unless Pathname.new(value).absolute?
    end
  end

  newparam(:user) do
    defaultto 'root'
    desc "The user to run 'wsadmin' with"
    validate do |value|
      unless value =~ /^[-0-9A-Za-z._]+$/
        fail("Invalid user #{value}")
      end
    end
  end

  newparam(:dmgr_host) do
    desc <<-EOT
      The DMGR host to add this node to.

      This is required if you're exporting the node for a DMGR to
      collect.  Otherwise, it's optional.
    EOT
  end

  newparam(:wsadmin_user) do
    desc "The username for wsadmin authentication"
  end

  newparam(:wsadmin_pass) do
    desc "The password for wsadmin authentication"
  end
end
