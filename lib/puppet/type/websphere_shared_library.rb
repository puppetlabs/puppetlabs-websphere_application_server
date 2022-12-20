# frozen_string_literal: true

require 'pathname'

Puppet::Type.newtype(:websphere_shared_library) do
  @doc = <<-DOC
    @summary This manages WebSphere Shared libraries.
    @example
      websphere_shared_library { 'exampleClusterSharedLibrary':
        ensure                => 'present',
        dmgr_profile          => 'PROFILE_DMGR_01',
        profile_base          => '/opt/IBM/WebSphere/AppServer/profiles',
        user                  => 'webadmin',
        cell                  => 'CELL_01',
        node_name             => 'AppNode01',
        cluster               => 'TEST_CLUSTER',
        scope                 => 'cluster',
        class_path            => [
          '/opt/IBM/shared_libraries/example',
          '/tmp/shared_libraries/example',
        ],
        native_path           => [
          '/tmp',
        ],
        isolated_class_loader => false,
        description           => 'Created by Puppet',
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
      # /opt/IBM/WebSphere/AppServer/profiles:PROFILE_DMGR_01:cell:CELL_01:PuppetTest
      [
        %r{^(.*):(.*):(cell):(.*):(.*)$},
        [
          [:profile_base],
          [:dmgr_profile],
          [:scope],
          [:cell],
          [:name],
        ],
      ],
      # /opt/IBM/WebSphere/AppServer/profiles:PROFILE_DMGR_01:cluster:CELL_01:TEST_CLUSTER_01:PuppetTest
      [
        %r{^(.*):(.*):(cluster):(.*):(.*):(.*)$},
        [
          [:profile_base],
          [:dmgr_profile],
          [:scope],
          [:cell],
          [:cluster],
          [:name],
        ],
      ],
      # /opt/IBM/WebSphere/AppServer/profiles:PROFILE_DMGR_01:node:CELL_01:AppNode01:PuppetTest
      [
        %r{^(.*):(.*):(node):(.*):(.*):(.*)$},
        [
          [:profile_base],
          [:dmgr_profile],
          [:scope],
          [:cell],
          [:node_name],
          [:name],
        ],
      ],
      # /opt/IBM/WebSphere/AppServer/profiles:PROFILE_DMGR_01:server:CELL_01:AppNode01:AppServer01:PuppetTest
      [
        %r{^(.*):(.*):(server):(.*):(.*):(.*)$},
        [
          [:profile_base],
          [:dmgr_profile],
          [:scope],
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

    Defaults to `true`.  Specifies whether this shared library should exist or not.
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
    [:dmgr_profile, :name, :user, :node, :cell].each do |value|
      raise ArgumentError, "Invalid #{value} #{self[value]}" unless %r{^[-0-9A-Za-z._]+$}.match?(value)
    end

    raise ArgumentError, "Invalid scope #{self[:scope]}: Must be cell, cluster, node, or server" unless %r{^(cell|cluster|node|server)$}.match?(self[:scope])

    raise ArgumentError, 'server is required when scope is server' if self[:server].nil? && self[:scope] == 'server'
    raise ArgumentError, 'cell is a required attribute' if self[:cell].nil?
    raise ArgumentError, 'node is required when scope is server, cell, or node' if self[:node_name].nil? && self[:scope] =~ %r{(server|cell|node)}
    raise ArgumentError, 'cluster is required when scope is cluster' if self[:cluster].nil? && self[:scope] =~ %r{^cluster$}
    raise("Invalid profile_base #{self[:profile_base]}") unless Pathname.new(self[:profile_base]).absolute?

    if self[:profile].nil?
      raise ArgumentError, 'profile is required' unless self[:dmgr_profile]
      self[:profile] = self[:dmgr_profile]
    end

    raise ArgumentError, 'class_path is required' if self[:class_path].nil?
  end

  newparam(:name) do
    isnamevar
    desc 'The name of the resource'
  end

  newproperty(:class_path, array_matching: :all) do
    desc <<-EOT
    Required. Specifies a class path that contains the JAR files for this library.
    Entries must not contain path separator characters (such as ';' or ':'). Class paths can contain variable (symbolic) names that can be substituted using a variable map.
    EOT
    # Override insync? to make sure we're comparing sorted arrays
    def insync?(is)
      is.sort == should.sort
    end
  end

  newparam(:scope) do
    isnamevar
    desc <<-EOT
    Required. The scope of namespace binding.
    Valid values: cell, node, cluster, node group or server .
    If scope is node, the cell and the node must be specified in their parameters.
    If scope is cluster, the cell and the cluster must be specified in their parameters.
    If scope is server, the cell, the node, and the server must be specified in their parameters.
    EOT
  end

  newproperty(:native_path, array_matching: :all) do
    desc <<-EOT
    Specifies an optional path to any native libraries (DLL or SO files) required by this shared library.
    EOT
    # Override insync? to make sure we're comparing sorted arrays
    def insync?(is)
      is.sort == should.sort
    end
  end

  newproperty(:description) do
    desc <<-EOT
    The description of the shared library.
    EOT
  end

  newproperty(:isolated_class_loader) do
    desc <<-EOT
    Use an isolated class loader for this shared library.
    EOT

    newvalues(:true, :false)

    munge do |value|
      value.to_s
    end
  end

  newparam(:node) do
    isnamevar
    desc 'The name of the node to create this application server on'
  end

  newparam(:cluster) do
    isnamevar
    desc 'The name of the cluster to create this application server on'
  end

  newparam(:server) do
    isnamevar
    desc 'The name of the server to create this application server on'
  end

  newparam(:cell) do
    isnamevar
    desc 'The name of the cell to create this application server on'
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
end
