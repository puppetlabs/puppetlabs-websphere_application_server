# frozen_string_literal: true

require 'pathname'

Puppet::Type.newtype(:websphere_jvm_custom_property) do
  @doc = <<-DOC
    @summary This manages WebSphere jvm custom properties.
    @example
      websphere_jvm_custom_property { 'exampleCustomProperty':
        ensure          => 'present',
        dmgr_profile    => 'PROFILE_DMGR_01',
        profile_base    => '/opt/IBM/WebSphere/AppServer/profiles',
        user            => 'webadmin',
        cell            => 'CELL_01',
        node_name       => 'AppNode01',
        server          => 'AppServer_01',
        property_value  => 'ValueGoesHere',
        description     => 'Created by Puppet',
      }
      # DMGR
      websphere_jvm_custom_property { '/opt/IBM/WebSphere/AppServer/profiles:PROFILE_DMGR_01:CELL_01:DMGR_01:dmgr:PuppetTest':
        ensure          => 'present',
        dmgr_profile    => 'PROFILE_DMGR_01',
        profile_base    => '/opt/IBM/WebSphere/AppServer/profiles',
        user            => 'webadmin',
        cell            => 'CELL_01',
        node_name       => 'DMGR_01',
        server          => 'dmgr',
        property_value  => 'ValueGoesHere',
        description     => 'Created by Puppet',
      }
      # AppServer nodeagent
      websphere_jvm_custom_property { '/opt/IBM/WebSphere/AppServer/profiles:PROFILE_DMGR_01:CELL_01:AppNode_01:nodeagent:PuppetTest':
        ensure          => 'present',
        dmgr_profile    => 'PROFILE_DMGR_01',
        profile_base    => '/opt/IBM/WebSphere/AppServer/profiles',
        user            => 'webadmin',
        cell            => 'CELL_01',
        node_name       => 'AppNode_01',
        server          => 'nodeagent',
        property_value  => 'ValueGoesHere',
        description     => 'Created by Puppet',
      }
  DOC

  # Our title_patterns method for mapping titles to namevars for supporting
  # composite namevars.
  def self.title_patterns
    [
      # PuppetTest
      [
        %r{^([^:]+)$},
        [
          [:name],
        ],
      ],
      # /opt/IBM/WebSphere/AppServer/profiles:PuppetTest
      [
        %r{^(.*):(.*)$},
        [
          [:profile_base],
          [:name],
        ],
      ],
      # /opt/IBM/WebSphere/AppServer/profiles:PROFILE_DMGR_01:PuppetTest
      [
        %r{^(.*):(.*):(.*)$},
        [
          [:profile_base],
          [:dmgr_profile],
          [:name],
        ],
      ],
      # /opt/IBM/WebSphere/AppServer/profiles:PROFILE_DMGR_01:CELL_01:AppNode_01:AppServer01:PuppetTest
      [
        %r{^(.*):(.*):(.*):(.*):(.*):(.*)$},
        [
          [:profile_base],
          [:dmgr_profile],
          [:cell],
          [:node_name],
          [:server],
          [:name],
        ],
      ],
    ]
  end

  ensurable do
    desc <<-EOT
    Valid values: `present`, `absent`

    Defaults to `present`.  Specifies whether this custom property should exist or not.
    EOT

    defaultto(:present)

    newvalue(:present) do
      provider.create
    end

    newvalue(:absent) do
      provider.destroy
    end
  end

  validate do
    [:dmgr_profile, :name, :user, :node_name, :cell].each do |value|
      raise ArgumentError, "Invalid #{value} #{self[value]}" unless %r{^[-0-9A-Za-z._]+$}.match?(value)
    end

    raise ArgumentError, 'server is required attribute' if self[:server].nil?
    raise ArgumentError, 'cell is a required attribute' if self[:cell].nil?
    raise ArgumentError, 'node is required attribute' if self[:node_name].nil?
    raise("Invalid profile_base #{self[:profile_base]}") unless Pathname.new(self[:profile_base]).absolute?

    if self[:profile].nil?
      raise ArgumentError, 'profile is required' unless self[:dmgr_profile]
      self[:profile] = self[:dmgr_profile]
    end
  end

  newparam(:name) do
    isnamevar
    desc 'The name of the resource'
  end

  newparam(:scope) do
    isnamevar
    desc <<-EOT
    Required. The scope of this configuration.
    Valid values: cell, node, cluster, node group or server .
    If scope is node, the cell and the node must be specified in their parameters.
    If scope is cluster, the cell and the cluster must be specified in their parameters.
    If scope is server, the cell, the node, and the server must be specified in their parameters.
    EOT
  end

  newproperty(:description) do
    desc <<-EOT
    The description of the JVM custom property.
    EOT
  end

  newproperty(:property_value) do
    desc <<-EOT
    The value of the JVM custom property.
    EOT
  end

  newparam(:node_name) do
    isnamevar
    desc 'The name of the node to create this JVM custom property on'
  end

  newparam(:cluster) do
    desc 'The name of the cluster to create this JVM custom property on'
  end

  newparam(:server) do
    isnamevar
    desc 'The name of the server to create this JVM custom property on'
  end

  newparam(:cell) do
    isnamevar
    desc 'The name of the cell to create this JVM custom property on'
  end

  newparam(:profile) do
    desc "The profile to run 'wsadmin' under"
  end

  newparam(:dmgr_profile) do
    isnamevar
    defaultto { @resource[:profile] }
    desc <<-EOT
    The dmgr profile that this variable should be set under.  Basically, where
    are we finding `wsadmin`

    This is synonomous with the 'profile' parameter.

    Example: dmgrProfile01
    EOT
  end

  newparam(:profile_base) do
    isnamevar
    desc <<-EOT
    The base directory that profiles are stored.
    Basically, where can we find the 'dmgr_profile' so we can run 'wsadmin'
    Example: /opt/IBM/WebSphere/AppServer/profiles"
    EOT
  end

  newparam(:user) do
    defaultto 'root'
    desc "The user to run 'wsadmin' with"
  end

  newparam(:wsadmin_user) do
    desc 'The username for wsadmin authentication'
  end

  newparam(:wsadmin_pass) do
    desc 'The password for wsadmin authentication'
  end

  newparam(:dmgr_host) do
    desc <<-EOT
      The DMGR host to add this cluster member to.

      This is required if you're exporting the cluster member for a DMGR to
      collect.  Otherwise, it's optional.
    EOT
  end
end
