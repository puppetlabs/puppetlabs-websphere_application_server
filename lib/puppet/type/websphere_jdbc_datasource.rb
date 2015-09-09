require 'pathname'

Puppet::Type.newtype(:websphere_jdbc_datasource) do

  autorequire(:user) do
    self[:user]
  end

  autorequire(:websphere_jdbc_provider) do
    self[:jdbc_provider]
  end

  ensurable

  validate do
    [:dmgr_profile, :name, :user, :node].each do |value|
      raise ArgumentError, "Invalid #{value.to_s} #{self[:value]}" unless value =~ /^[-0-9A-Za-z._]+$/
    end

    fail("Invalid profile_base #{self[:profile_base]}") unless Pathname.new(self[:profile_base]).absolute?
    raise ArgumentError 'Invalid scope, must be "node", "server", "cell", or "cluster"' unless self[:scope] =~ /^(node|server|cell|cluster)$/
  end

  newparam(:name) do
    isnamevar
    desc "The name of the datasource"
  end

  newparam(:dmgr_profile) do
    desc <<-EOT
    The dmgr profile that this should be created under"
    Example: dmgrProfile01"
    EOT
  end

  newparam(:profile_base) do
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

  newparam(:node) do
    desc "The name of the node to create this application server on"
  end

  newparam(:server) do
    desc "The name of the server to create this application server on"
  end

  newparam(:cluster) do
    desc "The name of the cluster to create this application server on"
  end

  newparam(:cell) do
    desc "The name of the cell to create this application server on"
  end

  newparam(:scope) do
    desc <<-EOT
    The scope to manage the JDBC Datasource at.
    Valid values are: node, server, cell, or cluster
    EOT
  end

  newparam(:jdbc_provider) do
    desc <<-EOT
    The name of the JDBC Provider to use.
    EOT
  end

  newparam(:jndi_name) do
    desc <<-EOT
    The JNDI name.
    This corresponds to the wsadmin argument '-jndiName'

    Example: 'jdbc/foo'
    EOT

  end

  newparam(:data_store_helper_class) do
    desc <<-EOT
    Example: 'com.ibm.websphere.rsadapter.Oracle11gDataStoreHelper'
    EOT
  end

  newparam(:container_managed_persistence) do
    desc <<-EOT
    Use this data source in container managed persistence (CMP)

    Boolean: true or false
    EOT
    newvalues(:true, :false)
    defaultto :true
  end

  newparam(:component_managed_auth_alias) do
    desc <<-EOT
    The alias used for database authentication at run time.
    This alias is only used when the application resource 
    reference is using res-auth=Application.

    String: Optional
    EOT
  end

  newparam(:url) do
    desc <<-EOT
    JDBC URL for Oracle providers.

    This is only relevant when the 'data_store_helper_class' is:
      'com.ibm.websphere.rsadapter.Oracle11gDataStoreHelper'

    Example: 'jdbc:oracle:thin:@//localhost:1521/sample'
    EOT
  end

  newparam(:description) do
    desc <<-EOT
    A description for the data source
    EOT
  end

  newparam(:db2_driver) do
    desc <<-EOT
    The driver for DB2.

    This only applies when the 'data_store_helper_class' is
    'com.ibm.websphere.rsadapter.DB2UniversalDataStoreHelper'
    EOT
  end

  newparam(:database) do
    desc <<-EOT
    The database name for DB2 and Microsoft SQL Server.

    This is only relevant when the 'data_store_helper_class' is one of:
      'com.ibm.websphere.rsadapter.DB2UniversalDataStoreHelper'
      'com.ibm.websphere.rsadapter.MicrosoftSQLServerDataStoreHelper'
    EOT
  end

  newparam(:db_server) do
    desc <<-EOT
    The database server address.

    This is only relevant when the 'data_store_helper_class' is one of:
      'com.ibm.websphere.rsadapter.DB2UniversalDataStoreHelper'
      'com.ibm.websphere.rsadapter.MicrosoftSQLServerDataStoreHelper'
    EOT
  end

  newparam(:db_port) do
    desc <<-EOT
    The database server port.

    This is only relevant when the 'data_store_helper_class' is one of:
      'com.ibm.websphere.rsadapter.DB2UniversalDataStoreHelper'
      'com.ibm.websphere.rsadapter.MicrosoftSQLServerDataStoreHelper'
    EOT
  end

  newparam(:wsadmin_user) do
    desc "The username for wsadmin authentication"
  end

  newparam(:wsadmin_pass) do
    desc "The password for wsadmin authentication"
  end
end
