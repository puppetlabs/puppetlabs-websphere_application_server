### Type: `websphere_jvm_log`

Manages JVM logging properties.

#### Example

```puppet
websphere_jvm_log { 'AppNode02 JVM Logs':
  profile_base        => '/opt/IBM/WebSphere/AppServer/profiles',
  dmgr_profile        => 'PROFILE_DMGR_01',
  cell                => 'CELL_01',
  scope               => 'node',
  node                => 'appNode02',
  server              => 'AppServer02',
  out_filename        => '/var/was/SystemOut.log',
  out_rollover_type   => 'BOTH',
  out_rollover_size   => '7',
  out_maxnum          => '200',
  out_start_hour      => '13',
  out_rollover_period => '24',
  err_filename        => '/var/was/SystemErr.log',
  err_rollover_type   => 'BOTH',
  err_rollover_size   => '7',
  err_maxnum          => '3',
  err_start_hour      => '13',
  err_rollover_period => '24',
}
```

#### Parameters

##### `scope`

Required. The scope to manage the properties at.

Valid values are 'node' and 'server'

##### `server`

The server to manage the properties on. Required if `scope` is 'server'

##### `cell`

Required. The cell that the node or server belongs to

##### `node`

Required.  The node to manage properties on.

##### `out_filename`

The file `System`.out filename. Can include WebSphere variables

##### `err_filename`

The file `System`.err filename. Can include WebSphere variables

##### `out_rollover_type`

Type of log rotation to enable for "SystemOut"

Valid values are: `SIZE`, `TIME`, or `BOTH`

##### `err_rollover_type`

Type of log rotation to enable for "SystemErr"

Valid values are: `SIZE`, `TIME`, or `BOTH`

##### `out_rollover_size`

Filesize in MB for log rotation of SystemOut.

##### `err_rollover_size`

Filesize in MB for log rotation of SystemErr.

##### `out_maxnum`

Maximum number of historical log files for SystemOut. 1-200.

##### `err_maxnum`

Maximum number of historical log files for SystemErr. 1-200.

##### `out_start_hour`

Start time for time-based log rotation of SystemOut. 1-24.

##### `err_start_hour`

Start time for time-based log rotation of SystemErr. 1-24.

##### `out_rollover_period`

Time period (log repeat time) for time-based log rotation of SystemOut. 1-24.

##### `err_rollover_period`

Time period (log repeat time) for time-based log rotation of SystemErr. 1-24.

##### `profile`
##### `name`


##### `name`

The name of the application server to create or manage.  Defaults to the
resource title.

##### `node`

Required. The name of the _node_ to create this server on.  Refer to the
`websphere_node` type for managing the creation of nodes.

##### `dmgr_profile`

Required. The name of the DMGR profile to create this application server under.

Examples: `PROFILE_DMGR_01` or `dmgrProfile01`

##### `profile_base`

Required. The full path to the profiles directory where the `dmgr_profile` can
be found.  The IBM default is `/opt/IBM/WebSphere/AppServer/profiles`

##### `user`

Optional. The user to run the `wsadmin` command as. Defaults to "root"

##### `wsadmin_user`

Optional. The username for `wsadmin` authentication if security is enabled.

##### `wsadmin_pass`

Optional. The password for `wsadmin` authentication if security is enabled.
