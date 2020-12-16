# frozen_string_literal: true

require 'pathname'

Puppet::Type.newtype(:websphere_jdbc_datasource_custom_property) do
  @doc = <<-DOC
    @summary This manages WebSphere JDBC datasource custom properties.
    @example
      websphere_jdbc_datasource_custom_property { 'exampleCustomProperty':
        ensure          => 'present',
        dmgr_profile    => 'PROFILE_DMGR_01',
        profile_base    => '/opt/IBM/WebSphere/AppServer/profiles',
        user            => 'webadmin',
        cell            => 'CELL_01',
        node_name       => 'AppNode01',
        cluster         => 'TEST_CLUSTER',
        scope           => 'cluster',
        java_type       => 'String',
        jdbc_provider   => 'ORACLE_JDBC_DRIVER_TEST_CLUSTER',
        jdbc_datasource => 'TEST_DS_01',
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
      # /opt/IBM/WebSphere/AppServer/profiles:PROFILE_DMGR_01:cluster:CELL_01:TEST_CLUSTER_01:JDBCProviderName:JDBCDatasourceName:PuppetTest
      [
        %r{^(.*):(.*):(cluster):(.*):(.*):(.*)$},
        [
          [:profile_base],
          [:dmgr_profile],
          [:scope],
          [:cell],
          [:cluster],
          [:jdbc_provider],
          [:jdbc_datasource],
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
      # /opt/IBM/WebSphere/AppServer/profiles:PROFILE_DMGR_01:node:CELL_01:AppNode01:JDBCProviderName:JDBCDatasourceName:PuppetTest
      [
        %r{^(.*):(.*):(node):(.*):(.*):(.*)$},
        [
          [:profile_base],
          [:dmgr_profile],
          [:scope],
          [:cell],
          [:node_name],
          [:jdbc_provider],
          [:jdbc_datasource],
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
      # /opt/IBM/WebSphere/AppServer/profiles:PROFILE_DMGR_01:server:CELL_01:AppNode01:AppServer01:JDBCProviderName:JDBCDatasourceName:PuppetTest
      [
        %r{^(.*):(.*):(server):(.*):(.*):(.*)$},
        [
          [:profile_base],
          [:dmgr_profile],
          [:scope],
          [:cell],
          [:node_name],
          [:server],
          [:jdbc_provider],
          [:jdbc_datasource],
          [:name],
        ],
      ],
    ]
  end

  autorequire(:websphere_jdbc_provider) do
    self[:jdbc_provider]
  end

  autorequire(:websphere_jdbc_datasource) do
    self[:jdbc_datasource]
  end

  ensurable do
    desc <<-EOT
    Valid values: `present`, `absent`

    Defaults to `true`.  Specifies whether this custom property should exist or not.
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
      raise ArgumentError, "Invalid #{value} #{self[value]}" unless value =~ %r{^[-0-9A-Za-z._]+$}
    end

    raise ArgumentError, "Invalid scope #{self[:scope]}: Must be cell, cluster, node, or server" unless self[:scope] =~ %r{^(cell|cluster|node|server)$}

    raise ArgumentError, 'server is required when scope is server' if self[:server].nil? && self[:scope] == 'server'
    raise ArgumentError, 'cell is a required attribute' if self[:cell].nil?
    raise ArgumentError, 'node is required when scope is server, cell, or node' if self[:node_name].nil? && self[:scope] =~ %r{(server|cell|node)}
    raise ArgumentError, 'cluster is required when scope is cluster' if self[:cluster].nil? && self[:scope] =~ %r{^cluster$}
    raise ArgumentError, 'jdbc_datasource is required' if self[:jdbc_datasource].nil?
    raise ArgumentError, 'jdbc_provider is required' if self[:jdbc_provider].nil?
    raise("Invalid profile_base #{self[:profile_base]}") unless Pathname.new(self[:profile_base]).absolute?

    if self[:profile].nil?
      raise ArgumentError, 'profile is required' unless self[:dmgr_profile]
      self[:profile] = self[:dmgr_profile]
    end

    unless self[:java_type] =~ %r{^(String|Integer|Double|Float|Short|Long|Byte|Boolean)$}
      raise ArgumentError, "Invalid java_type #{self[:java_type]}: Must be String, Integer, Double, Float, Short, Long, Byte, or Boolean"
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

  newparam(:jdbc_provider) do
    isnamevar
    desc <<-EOT
    The name of the JDBC Provider to use.
    EOT
  end

  newparam(:jdbc_datasource) do
    isnamevar
    desc <<-EOT
    Required. The name of the JDBC Datasource to use.
    EOT
  end

  newparam(:java_type) do
    desc <<-EOT
    Specifies the Java lang type of this property.
    EOT
  end

  newproperty(:description) do
    desc <<-EOT
    The description of the datasource custom property.
    EOT
  end

  newproperty(:property_value) do
    desc <<-EOT
    The value of the datasource custom property.
    EOT
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
