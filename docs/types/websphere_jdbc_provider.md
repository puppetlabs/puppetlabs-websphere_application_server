### Type: `websphere_jdbc_provider`

Manages the existence of a WebSphere JDBC provider.

The current provider does _not_ manage parameters post-creation.

#### Example

```puppet
websphere_jdbc_provider { 'Puppet Test':
  ensure         => 'present',
  dmgr_profile   => 'PROFILE_DMGR_01',
  profile_base   => '/opt/IBM/WebSphere/AppServer/profiles',
  user           => 'webadmins',
  scope          => 'node',
  cell           => 'CELL_01',
  node           => 'appNode01',
  server         => 'AppServer01',
  dbtype         => 'Oracle',
  providertype   => 'Oracle JDBC Driver',
  implementation => 'Connection pool data source',
  description    => 'Created by Puppet',
  classpath      => '${ORACLE_JDBC_DRIVER_PATH}/ojdbc6.jar',
}
```

#### Parameters

##### `ensure`

Valid values: `present`, `absent`

Defaults to `present`.  Specifies whether this provider should exist or not.

##### `scope`

Required. The _scope_ to manage this JDBC provider at.

Valid values are: node, server, cell, or cluster.

##### `cell`

Required.  The cell that this provider should be managed under.

##### `node`

Required if `scope` is server or node.

##### `server`

Required if `scope` is server.

##### `cluster`

Required if `scope` is cluster.

##### `dbtype`

The type of database for the JDBC Provider.
This corresponds to the wsadmin argument `-databaseType`
Examples: DB2, Oracle

Consult IBM's documentation for the types of valid databases.

##### `providertype`

The provider type for this JDBC Provider.
This corresponds to the wsadmin argument `-providerType`

Examples:

* "Oracle JDBC Driver"
* "DB2 Universal JDBC Driver Provider"
* "DB2 Using IBM JCC Driver"

Consult IBM's documentation for valid provider types.

##### `implementation`

The implementation type for this JDBC Provider.
This corresponds to the wsadmin argument `-implementationType`

Example: "Connection pool data source"

Consult IBM's documentation for valid implementation types.

##### `classpath`

The classpath for this provider.
This corresponds to the wsadmin argument `-classpath`

Examples:

* `${ORACLE_JDBC_DRIVER_PATH}/ojdbc6.jar`
* `${DB2_JCC_DRIVER_PATH}/db2jcc4.jar ${UNIVERSAL_JDBC_DRIVER_PATH}/db2jcc_license_cu.jar`

Consult IBM's documentation for valid classpaths.

##### `nativepath`

The nativepath for this provider.
This corresponds to the wsadmin argument `-nativePath`

This can be blank.

Examples: `${DB2UNIVERSAL_JDBC_DRIVER_NATIVEPATH}`

Consult IBM's documentation for valid native paths.

##### `dmgr_profile`

Required. The name of the DMGR _profile_ that this provider should be
managed under.

##### `profile_base`

Required. The full path to the profiles directory where the `dmgr_profile` can
be found.  The IBM default is `/opt/IBM/WebSphere/AppServer/profiles`

##### `name`

The name of the provider. Defaults to the resource title.

##### `description`

An optional description for the provider.

##### `user`

Optional. The user to run the `wsadmin` command as. Defaults to "root"

##### `wsadmin_user`

Optional. The username for `wsadmin` authentication if security is enabled.

##### `wsadmin_pass`

Optional. The password for `wsadmin` authentication if security is enabled.
