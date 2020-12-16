# frozen_string_literal: true

require 'pathname'

Puppet::Type.newtype(:websphere_cluster) do
  @doc = <<-DOC
    @summary Manages the creation or removal of WebSphere server clusters.
    DOC

  ensurable

  newparam(:dmgr_profile) do
    desc <<-EOT
      Required. The name of the DMGR profile to create this application server
      under.

      Examples: `PROFILE_DMGR_01` or `dmgrProfile01`
    EOT

    validate do |value|
      unless %r{^[-0-9A-Za-z._]+$}.match?(value)
        raise("Invalid dmgr_profile #{value}")
      end
    end
  end

  newparam(:profile) do
    desc <<-EOT
      Optional. The profile of the server to use for executing wsadmin
      commands. Will default to dmgr_profile if not set.
    EOT
  end

  newparam(:name) do
    isnamevar

    desc 'The name of the cluster to manage.'

    validate do |value|
      unless %r{^[-0-9A-Za-z._]+$}.match?(value)
        raise("Invalid name #{value}")
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
      raise("Invalid profile_base #{value}") unless Pathname.new(value).absolute?
    end
  end

  newparam(:user) do
    defaultto 'root'

    desc <<-EOT
      Optional. The user to run the `wsadmin` command as. Defaults to "root"
    EOT

    validate do |value|
      unless %r{^[-0-9A-Za-z._]+$}.match?(value)
        raise("Invalid user #{value}")
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
