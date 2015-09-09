require 'pathname'

Puppet::Type.newtype(:websphere_jdbc_provider) do

  @doc = <<-EOT
    Manages the existence of a WebSphere JDBC provider.

    The current provider does _not_ manage parameters post-creation.
  EOT

  autorequire(:user) do
    self[:user]
  end

  ensurable

  validate do
    [:dmgr_profile, :name, :user].each do |value|
      raise ArgumentError, "Invalid #{value.to_s} #{self[:value]}" unless value =~ /^[-0-9A-Za-z._]+$/
    end

    fail("Invalid profile_base #{self[:profile_base]}") unless Pathname.new(self[:profile_base]).absolute?
    raise ArgumentError 'Invalid scope, must be "node", "server", "cell", or "cluster"' unless self[:scope] =~ /^(node|server|cell|cluster)$/
  end

  newparam(:dmgr_profile) do
    desc <<-EOT
      Required. The name of the DMGR _profile_ that this provider should be
      managed under.
    EOT
  end

  newparam(:name) do
    isnamevar
    desc 'The name of the provider.'
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

  newparam(:node) do
    desc <<-EOT
      Required if `scope` is server or node.
    EOT
  end

  newparam(:server) do
    desc <<-EOT
      Required if `scope` is server.
    EOT
  end

  newparam(:cluster) do
    desc <<-EOT
      Required if `scope` is cluster.
    EOT
  end

  newparam(:cell) do
    desc <<-EOT
      Required.  The cell that this provider should be managed under.
    EOT
  end

  newparam(:scope) do
    desc <<-EOT
    The scope to manage the JDBC Provider at.
    Valid values are: node, server, cell, or cluster
    EOT
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

  newparam(:description) do
    desc <<-EOT
    An optional description for this provider
    EOT
  end

  newparam(:classpath) do
    desc <<-EOT
    The classpath for this provider.
    This corresponds to the wsadmin argument "-classpath"

    Examples:
      "${ORACLE_JDBC_DRIVER_PATH}/ojdbc6.jar"
      "${DB2_JCC_DRIVER_PATH}/db2jcc4.jar ${UNIVERSAL_JDBC_DRIVER_PATH}/db2jcc_license_cu.jar"

    Consult IBM's documentation for valid classpaths.
    EOT
  end

  newparam(:nativepath) do
    desc <<-EOT
    The nativepath for this provider.
    This corresponds to the wsadmin argument "-nativePath"

    This can be blank.

    Examples:
      "${DB2UNIVERSAL_JDBC_DRIVER_NATIVEPATH}"

    Consult IBM's documentation for valid native paths.
    EOT
  end

  newparam(:wsadmin_user) do
    desc "The username for wsadmin authentication"
  end

  newparam(:wsadmin_pass) do
    desc "The password for wsadmin authentication"
  end
end
