# frozen_string_literal: true

require 'pathname'

Puppet::Type.newtype(:websphere_variable) do
  @doc = <<-DOC
    @summary This manages a WebSphere environment variable
    @example
      websphere_variable { 'PuppetTestVariable':
        ensure       => 'present',
        dmgr_profile => 'PROFILE_DMGR_01',
        profile_base => '/opt/IBM/WebSphere/AppServer/profiles',
        user         => 'webadmin',
        cell         => 'CELL_01',
        node_name    => 'AppNode01',
        cluster      => 'TEST_CLUSTER',
        value        => 'TestValue',
      }
  DOC

  ensurable

  # Our title_patterns method for mapping titles to namevars for supporting
  # composite namevars.
  def self.title_patterns
    [
      # varName
      [
        %r{^([^:]+)$},
        [
          [:variable],
        ],
      ],
      # /opt/IBM/WebSphere/AppServer/profiles:varName
      [
        %r{^(.*):(.*)$},
        [
          [:profile_base],
          [:variable],
        ],
      ],
      # /opt/IBM/WebSphere/AppServer/profiles:PROFILE_DMGR_01:varName
      [
        %r{^(.*):(.*):(.*)$},
        [
          [:profile_base],
          [:dmgr_profile],
          [:variable],
        ],
      ],
      # /opt/IBM/WebSphere/AppServer/profiles:PROFILE_DMGR_01:cell:CELL_01:varName
      [
        %r{^(.*):(.*):(cell):(.*):(.*)$},
        [
          [:profile_base],
          [:dmgr_profile],
          [:scope],
          [:cell],
          [:variable],
        ],
      ],
      # /opt/IBM/WebSphere/AppServer/profiles:PROFILE_DMGR_01:cluster:CELL_01:TEST_CLUSTER_01:varName
      [
        %r{^(.*):(.*):(cluster):(.*):(.*):(.*)$},
        [
          [:profile_base],
          [:dmgr_profile],
          [:scope],
          [:cell],
          [:cluster],
          [:variable],
        ],
      ],
      # /opt/IBM/WebSphere/AppServer/profiles:PROFILE_DMGR_01:node:CELL_01:AppNode01:varName
      [
        %r{^(.*):(.*):(node):(.*):(.*):(.*)$},
        [
          [:profile_base],
          [:dmgr_profile],
          [:scope],
          [:cell],
          [:node_name],
          [:variable],
        ],
      ],
      # /opt/IBM/WebSphere/AppServer/profiles:PROFILE_DMGR_01:server:CELL_01:AppNode01:AppServer01:varName
      [
        %r{^(.*):(.*):(server):(.*):(.*):(.*)$},
        [
          [:profile_base],
          [:dmgr_profile],
          [:scope],
          [:cell],
          [:node_name],
          [:server],
          [:variable],
        ],
      ],
    ]
  end

  validate do
    raise ArgumentError, "Invalid scope #{self[:scope]}: Must be cell, cluster, node, or server" unless %r{^(cell|cluster|node|server)$}.match?(self[:scope])
    raise ArgumentError, 'server is required when scope is server' if self[:server].nil? && self[:scope] == 'server'
    raise ArgumentError, 'cell is required' if self[:cell].nil?
    raise ArgumentError, 'node is required when scope is server, cell, or node' if self[:node_name].nil? && self[:scope] =~ %r{(server|cell|node)}
    raise ArgumentError, 'cluster is required when scope is cluster' if self[:cluster].nil? && self[:scope] =~ %r{^cluster$}
    raise ArgumentError, "Invalid profile_base #{self[:profile_base]}" unless Pathname.new(self[:profile_base]).absolute?

    if self[:profile].nil?
      raise ArgumentError, 'profile is required' unless self[:dmgr_profile]
      self[:profile] = self[:dmgr_profile]
    end

    [:variable, :server, :cell, :node_name, :cluster, :profile, :user].each do |value|
      raise ArgumentError, "Invalid #{value} #{self[:value]}" unless %r{^[-0-9A-Za-z._]+$}.match?(value)
    end
  end

  newparam(:variable) do
    isnamevar
    desc <<-EOT
    Required. The name of the variable to create/modify/remove.  For example,
    `LOG_ROOT`
    EOT
  end

  newparam(:scope) do
    isnamevar
    desc <<-EOT
    The scope for the variable.
    Valid values: cell, cluster, node, or server
    EOT
  end

  newproperty(:value) do
    desc 'The value the variable should be set to.'
  end

  newproperty(:description) do
    desc 'A description for the variable'
  end

  newparam(:server) do
    isnamevar
    desc 'The server in the scope for this variable'
  end

  newparam(:cell) do
    isnamevar
    desc 'The cell that this variable should be set in'
  end

  newparam(:node_name) do
    isnamevar
    desc 'The node that this variable should be set under'
  end

  newparam(:cluster) do
    isnamevar
    desc 'The cluster that a variable should be set in'
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

    Example: dmgrProfile01"
    EOT
  end

  newparam(:profile_base) do
    isnamevar
    desc "The base directory that profiles are stored.
      Example: /opt/IBM/WebSphere/AppServer/profiles"
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
