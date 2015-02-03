### Type: `websphere_jdbc_datasource`

Manages the existence of a WebSphere datasource.

The current provider does _not_ manage parameters post-creation.

#### Example

```puppet
websphere_jdbc_datasource { 'Puppet Test':
  ensure                        => 'present',
  dmgr_profile                  => 'PROFILE_DMGR_01',
  profile_base                  => '/opt/IBM/WebSphere/AppServer/profiles',
  user                          => 'webadmins',
  scope                         => 'node',
  cell                          => 'CELL_01',
  node                          => 'appNode01',
  server                        => 'AppServer01',
  jdbc_provider                 => 'Puppet Test',
  jndi_name                     => 'puppetTest',
  data_store_helper_class       => 'com.ibm.websphere.rsadapter.Oracle11gDataStoreHelper',
  container_managed_persistence => true,
  url                           => 'jdbc:oracle:thin:@//localhost:1521/sample',
  description                   => 'Managed by Puppet',
}
```

#### Parameters

##### `ensure`

Valid values: `present`, `absent`

Defaults to `present`.  Specifies whether this datasource should exist or not.

##### `scope`

Required. The _scope_ to manage this JDBC datasource at.

Valid values are: node, server, cell, or cluster.

##### `cell`

Required.  The cell that this datasource should be managed under.

##### `node`

Required if `scope` is server or node.

##### `server`

Required if `scope` is server.

##### `cluster`

Required if `scope` is cluster.

##### `dmgr_profile`

Required. The name of the DMGR _profile_ that this datasource should be
managed under.

##### `profile_base`

Required. The full path to the profiles directory where the `dmgr_profile` can
be found.  The IBM default is `/opt/IBM/WebSphere/AppServer/profiles`

##### `name`

The name of the datasource.  Defaults to the resource title.

##### `jdbc_provider`

Required. The name of the JDBC provider to use for this datasource.

##### `jndi_name`

Required. The JNDI name. This corresponds to the `wsadmin` argument `-jndiName`

Example: `jndc/foo`

##### `data_store_helper_class`

Required.  Corresponds to the `wsadmin` argument `-dataStoreHelperClassName`

Examples: `com.ibm.websphere.rsadapter.Oracle11gDataStoreHelper` or
`com.ibm.websphere.rsadapter.Oracle11gDataStoreHelper`

##### `container_managed_persistence`

AKA "CMP"

Boolean.

Corresponds to the `wsadmin` argument `-componentManagedAuthenticationAlias`

##### `url`

Required for Oracle providers.

The JDBC URL.

Only relevant when the `data_store_helper_class` is
`com.ibm.websphere.rsadapter.Oracle11gDataStoreHelper`

Example: `jdbc:oracle:thin:@//localhost:1521/sample`

##### `description`

An optional description for the datasource.

##### `db2_driver`

The driver for DB2 datasources.  Only relevant when that's the provider.

This only applies when the `data_store_helper_class` is
`com.ibm.websphere.rsadapter.DB2UniversalDataStoreHelper`

##### `database`

The database name for DB2 and Microsoft SQL Server.

This is only relevant when the `data_store_helper_class` is one of:

* `com.ibm.websphere.rsadapter.DB2UniversalDataStoreHelper`
* `com.ibm.websphere.rsadapter.MicrosoftSQLServerDataStoreHelper`

##### `db_server`

The database server address.

This is only relevant when the `data_store_helper_class` is one of:

* `com.ibm.websphere.rsadapter.DB2UniversalDataStoreHelper`
* `com.ibm.websphere.rsadapter.MicrosoftSQLServerDataStoreHelper`

##### `db_port`

The database server port.

This is only relevant when the `data_store_helper_class` is one of:

* `com.ibm.websphere.rsadapter.DB2UniversalDataStoreHelper`
* `com.ibm.websphere.rsadapter.MicrosoftSQLServerDataStoreHelper`

##### `component_managed_auth_alias`

Corresponds to the `wsadmin` argument `-componentManagedAuthenticationAlias`

##### `user`

Optional. The user to run the `wsadmin` command as. Defaults to "root"

##### `wsadmin_user`

Optional. The username for `wsadmin` authentication if security is enabled.

##### `wsadmin_pass`

Optional. The password for `wsadmin` authentication if security is enabled.
