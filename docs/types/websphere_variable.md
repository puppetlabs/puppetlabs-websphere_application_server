### Type: `websphere_variable`

Manages WebSphere environment variables.

Under the hood, the included provider is running `wsadmin`

#### Example

Manage a variable at _node_ scope on `appNode01`.  Setting the `LOG_ROOT`
variable.

```puppet
websphere_variable { 'appNode01Logs':
  ensure       => 'present',
  variable     => 'LOG_ROOT',
  value        => '/opt/log/websphere/wasmgmtlogs/appNode01',
  scope        => 'node',
  node         => 'appNode01',
  cell         => 'CELL_01',
  profile      => 'PROFILE_APP_001',
  profile_base => '/opt/IBM/WebSphere85/Profiles',
  user         => 'webadmins',
}
```

#### Parameters

##### `ensure`

Valid values: `present`, `absent`

Defaults to `true`.  Specifies whether this variable should exist or not.

##### `variable`

Required. The name of the variable to create/modify/remove.  For example,
`LOG_ROOT`

##### `value`

Required. The value that the specified variable should be set to.

##### `description`

Optional. A human-readable description for the variable.

Defaults to "Managed by Puppet"

##### `scope`

Required. The scope for the variable.

Valid values are: `cell`, `cluster`, `node`, or `server`

##### `server`

The server in the scope for this variable.

Required when `scope` is `server`

##### `cell`

Required. The cell that this variable should be set in.

##### `node`

The node that this variable should be set under.  This is required when scope
is set to `node` or `server`

##### `cluster`

The cluster that a variable should be set in.  This is required when scope is
set to `cluster`

##### `profile`

The profile that can be used to run the `wsadmin` command from.

Example: `dmgrProfile01` or `PROFILE_APP_01`

##### `dmgr_profile`

Synonomous with the `profile` parameter.

The DMGR profile that this variable should be set under.  The `wsadmin` tool
will be found here.

Example: `dmgrProfile01` or `PROFILE_DMGR_001`

##### `name`

The name of the resource. This is only used for Puppet to identify
the resource and has no influence over the commands used to make
modifications or query WebSphere variables.

##### `profile_base`

Required. The full path to the profiles directory where the `profile` can
be found.  The IBM default is `/opt/IBM/WebSphere/AppServer/profiles`

##### `user`

Optional. The user to run the `wsadmin` command as. Defaults to "root"

##### `wsadmin_user`

Optional. The username for `wsadmin` authentication if security is enabled.

##### `wsadmin_pass`

Optional. The password for `wsadmin` authentication if security is enabled.
