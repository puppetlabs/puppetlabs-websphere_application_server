require 'pathname'

Puppet::Type.newtype(:websphere_jdbc_datasource) do

  autorequire(:user) do
    self[:user] unless self[:user].to_s.nil?
  end

  autorequire(:websphere_jdbc_provider) do
    self[:jdbc_provider] unless self[:jdbc_provider].to_s.nil?
  end

  ensurable do
    desc "Manage the existence of a datasource"

    defaultto(:present)

    newvalue(:present) do
      provider.create
    end

    newvalue(:absent) do
      provider.destroy
    end

  end

  newparam(:dmgr_profile) do
    desc <<-EOT
    The dmgr profile that this should be created under"
    Example: dmgrProfile01"
    EOT

    validate do |value|
      unless value =~ /^[-0-9A-Za-z._]+$/
        fail("Invalid dmgr_profile #{value}")
      end
    end
  end

  newparam(:name) do
    isnamevar
    desc "The name of the datasource"
  end

  newparam(:profile_base) do
    desc <<-EOT
    The base directory that profiles are stored.
    Basically, where can we find the 'dmgr_profile' so we can run 'wsadmin'

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

  newparam(:node) do
    desc "The name of the node to create this application server on"
    validate do |value|
      unless value =~ /^[-0-9A-Za-z._]+$/
        fail("Invalid dmgr_profile #{value}")
      end
    end
  end

  newparam(:server) do

  end

  newparam(:cluster) do

  end

  newparam(:cell) do

  end

  newparam(:scope) do
    desc <<-EOT
    The scope to manage the JDBC Datasource at.
    Valid values are: node, server, cell, or cluster
    EOT
    # node, server, cell, cluster
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
    defaultto true
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

  newparam(:component_managed_auth_alias) do

  end

  newparam(:wsadmin_user) do
    desc "The username for wsadmin authentication"
  end

  newparam(:wsadmin_pass) do
    desc "The password for wsadmin authentication"
  end
end
