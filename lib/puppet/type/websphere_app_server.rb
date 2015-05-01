require 'pathname'

Puppet::Type.newtype(:websphere_app_server) do

  @doc = "Manage the existence of WebSphere Application Servers"

  ensurable

  newparam(:dmgr_profile) do
    desc <<-EOT
      Required. The name of the DMGR profile to create this application
      server under.

      Examples: `PROFILE_DMGR_01` or `dmgrProfile01`"
    EOT

    validate do |value|
      unless value =~ /^[-0-9A-Za-z._]+$/
        fail("Invalid dmgr_profile #{value}")
      end
    end
  end

  newparam(:name) do
    isnamevar

    desc 'The name of the application server to create or manage.'

    validate do |value|
      unless value =~ /^[-0-9A-Za-z._]+$/
        fail("Invalid name #{value}")
      end
    end
  end

  newparam(:node) do
    desc <<-EOT
      Required. The name of the _node_ to create this server on.  Refer to the
      `websphere_node` type for managing the creation of nodes.
    EOT
    validate do |value|
      unless value =~ /^[-0-9A-Za-z._]+$/
        fail("Invalid dmgr_profile #{value}")
      end
    end
  end

  newparam(:profile_base) do
    desc <<-EOT
      Required. The full path to the profiles directory where the
      `dmgr_profile` can be found.  The IBM default is
      `/opt/IBM/WebSphere/AppServer/profiles`
    EOT

    validate do |value|
      fail("Invalid profile_base #{value}") unless Pathname.new(value).absolute?
    end
  end

  newparam(:user) do
    desc <<-EOT
      Optional. The user to run the `wsadmin` command as. Defaults to "root"
    EOT

    defaultto 'root'
    validate do |value|
      unless value =~ /^[-0-9A-Za-z._]+$/
        fail("Invalid user #{value}")
      end
    end
  end

  newparam(:wsadmin_user) do
    desc <<-EOT
      Optional. The username for `wsadmin` authentication if security is
      enabled.
    EOT
  end

  newparam(:wsadmin_pass) do
    desc <<-EOT
      Optional. The password for `wsadmin` authentication if security is
      enabled.
    EOT
  end
end
