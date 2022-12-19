# frozen_string_literal: true

require 'pathname'

Puppet::Type.newtype(:websphere_jdbc_provider) do
  @doc = <<-DOC
    @summary Manages the presence and configuration of a WebSphere JDBC provider at a given scope.
    @example Create a JDBC provider at scope NODE:
      websphere_jdbc_provider { '/opt/IBM/WebSphere/AppServer/profiles:PROFILE_DMGR_01:node:CELL_01:AppNode01:PuppetJDBCProvider'
        ensure         => 'present',
        user           => 'webadmin',
        dbtype         => 'Oracle',
        providertype   => 'Oracle JDBC Driver',
        implementation => 'Connection pool data source',
        description    => 'Created by Puppet',
        classpath      => '${ORACLE_JDBC_DRIVER_PATH}/ojdbc6.jar',
      }
  DOC

  autorequire(:user) do
    self[:user]
  end

  ensurable

  # Our title_patterns method for mapping titles to namevars for supporting
  # composite namevars.
  def self.title_patterns
    [
      # ProviderName
      [
        %r{^([^:]+)$},
        [
          [:provider_name],
        ],
      ],
      # /opt/IBM/WebSphere/AppServer/profiles:ProviderName
      [
        %r{^([^:]+):([^:]+)$},
        [
          [:profile_base],
          [:provider_name],
        ],
      ],
      # /opt/IBM/WebSphere/AppServer/profiles:PROFILE_DMGR_01:ProviderName
      [
        %r{^([^:]+):([^:]+):([^:]+)$},
        [
          [:profile_base],
          [:dmgr_profile],
          [:provider_name],
        ],
      ],
      # /opt/IBM/WebSphere/AppServer/profiles:PROFILE_DMGR_01:cell:CELL_01:ProviderName
      [
        %r{^([^:]+):([^:]+):(cell):([^:]+):([^:]+)$},
        [
          [:profile_base],
          [:dmgr_profile],
          [:scope],
          [:cell],
          [:provider_name],
        ],
      ],
      # /opt/IBM/WebSphere/AppServer/profiles:PROFILE_DMGR_01:cluster:CELL_01:TEST_CLUSTER_01:ProviderName
      [
        %r{^([^:]+):([^:]+):(cluster):([^:]+):([^:]+):([^:]+)$},
        [
          [:profile_base],
          [:dmgr_profile],
          [:scope],
          [:cell],
          [:cluster],
          [:provider_name],
        ],
      ],
      # /opt/IBM/WebSphere/AppServer/profiles:PROFILE_DMGR_01:node:CELL_01:AppNode01:ProviderName
      [
        %r{^([^:]+):([^:]+):(node):([^:]+):([^:]+):([^:]+)$},
        [
          [:profile_base],
          [:dmgr_profile],
          [:scope],
          [:cell],
          [:node_name],
          [:provider_name],
        ],
      ],
      # /opt/IBM/WebSphere/AppServer/profiles:PROFILE_DMGR_01:server:CELL_01:AppNode01:AppServer01:ProviderName
      [
        %r{^([^:]+):([^:]+):(server):([^:]+):([^:]+):([^:]+):([^:]+)$},
        [
          [:profile_base],
          [:dmgr_profile],
          [:scope],
          [:cell],
          [:node_name],
          [:server],
          [:provider_name],
        ],
      ],
    ]
  end

  validate do
    raise ArgumentError, "Invalid scope #{self[:scope]}: Must be cell, cluster, node, or server" unless %r{^(cell|cluster|node|server)$}.match?(self[:scope])
    raise ArgumentError, 'server is required when scope is server' if self[:server].nil? && self[:scope] == 'server'
    raise ArgumentError, 'cell is required' if self[:cell].nil?
    raise ArgumentError, 'node_name is required when scope is server, or node' if self[:node_name].nil? && self[:scope] =~ %r{(server|node)}
    raise ArgumentError, 'cluster is required when scope is cluster' if self[:cluster].nil? && self[:scope] =~ %r{^cluster$}
    raise ArgumentError, "Invalid profile_base #{self[:profile_base]}" unless Pathname.new(self[:profile_base]).absolute?

    if self[:profile].nil?
      raise ArgumentError, 'profile is required' unless self[:dmgr_profile]
      self[:profile] = self[:dmgr_profile]
    end

    [:provider_name, :server, :cell, :node_name, :cluster, :profile, :user].each do |value|
      raise ArgumentError, "Invalid #{value} #{self[:value]}" unless %r{^[-0-9A-Za-z._]+$}.match?(value)
    end

    #if self[:isolated_class_loader] && !self[:nativepath].empty?
    #  raise ArgumentError, "Invalid parameter combination: cannot enable class loader isolation (#{self[:isolated_class_loader]}) when native path libraries are set: #{self[:nativepath].to_s}"
    #end
  end

  newparam(:provider_name) do
    isnamevar
    desc 'The name of the JDBC provider.'
  end

  newparam(:dbtype) do
    # db2, derby, informix, oracle, sybase, sql, user
    # DB2, User-defined, Oracle, SQL Server,
    # Microsoft SQL Server JDBC Driver
    desc <<-EOT
    The type of database for the JDBC Provider.
    This corresponds to the wsadmin argument "-databaseType"
    Examples: DB2, Oracle

    Consult IBM's documentation for the types of valid databases.
    EOT
  end

  newparam(:providertype) do
    desc <<-EOT
    The provider type for this JDBC Provider.
    This corresponds to the wsadmin argument "-providerType"

    Examples:
      "Oracle JDBC Driver"
      "DB2 Universal JDBC Driver Provider"
      "DB2 Using IBM JCC Driver"

    Consult IBM's documentation for valid provider types.
    EOT
  end

  newparam(:implementation) do
    desc <<-EOT
    The implementation type for this JDBC Provider.
    This corresponds to the wsadmin argument "-implementationType"

    Examples:
      "Connection pool data source"

    Consult IBM's documentation for valid implementation types.
    EOT
  end

  newproperty(:description) do
    desc <<-EOT
    An optional description for this provider
    EOT
    defaultto ''
  end

  newproperty(:classpath) do
    desc <<-EOT
    The classpath for this provider.
    This corresponds to the wsadmin argument "-classpath"

    Examples:
      "${ORACLE_JDBC_DRIVER_PATH}/ojdbc6.jar"
      "${DB2_JCC_DRIVER_PATH}/db2jcc4.jar ${UNIVERSAL_JDBC_DRIVER_PATH}/db2jcc_license_cu.jar"

    Consult IBM's documentation for valid classpaths.
    EOT
    defaultto []
  end

  newproperty(:nativepath) do
    desc <<-EOT
    The nativepath for this provider.
    This corresponds to the wsadmin argument "-nativePath"

    This can be blank.

    Examples:
      "${DB2UNIVERSAL_JDBC_DRIVER_NATIVEPATH}"

    Consult IBM's documentation for valid native paths.
    EOT
    defaultto []
  end

  newproperty(:implementation_classname) do
    desc <<-EOT
    Specifies the Java class name of the JDBC driver implementation.
    This class is available in the driver files mentioned in the classpath parameter.

    WARNING:
    This parameter is generally used with custom user-defined JDBC providers
    Modifying the implementation class name after the creation of the JDBC provider prevents the usage of templates to create JDBC data sources.

    Example:
      "oracle.jdbc.xa.client.OracleXADataSource"
    EOT
  end

  newproperty(:isolated_class_loader) do
    desc <<-EOT
    Specifies that this resource provider will be loaded in its own class loader. This allows different versions or implementations of the same resource provider to be loaded in the same Java Virtual Machine. Give each version of the resource provider a unique class path that is appropriate for that version or implementation.

    WARNING:
    You cannot isolate a resource provider if you specify a native library path.

    Boolean: true or false
    EOT
    newvalues(:true, :false)
    defaultto :false
  end

  newparam(:node_name) do
    isnamevar
    desc <<-EOT
      Required if `scope` is server or node.
    EOT
  end

  newparam(:server) do
    isnamevar
    desc <<-EOT
      Required if `scope` is server.
    EOT
  end

  newparam(:cluster) do
    isnamevar
    desc <<-EOT
      Required if `scope` is cluster.
    EOT
  end

  newparam(:cell) do
    isnamevar
    desc <<-EOT
      Required.  The cell that this provider should be managed under.
    EOT
  end

  newparam(:scope) do
    isnamevar
    desc <<-EOT
    The scope to manage the JDBC Provider at.
    Valid values are: node, server, cell, or cluster
    EOT
  end

  newparam(:dmgr_profile) do
    desc <<-EOT
      Required. The name of the DMGR _profile_ that this provider should be
      managed under.
    EOT
  end

  newparam(:profile) do
    desc <<-EOT
      Optional. The profile of the server to use for executing wsadmin
      commands. Will default to dmgr_profile if not set.
    EOT
  end

  newparam(:profile_base) do
    desc <<-EOT
      Required. The full path to the profiles directory where the
      `dmgr_profile` can be found.  The IBM default is
      `/opt/IBM/WebSphere/AppServer/profiles`
    EOT
  end

  newparam(:user) do
    defaultto 'root'
    desc <<-EOT
      Optional. The user to run the `wsadmin` command as. Defaults to 'root'
    EOT
  end

  newparam(:wsadmin_user) do
    desc 'The username for wsadmin authentication'
  end

  newparam(:wsadmin_pass) do
    desc 'The password for wsadmin authentication'
  end
end
