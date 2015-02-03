### Type: `websphere_app_server`

Manages the creation or removal of WebSphere Application Servers.

#### Example

```puppet
websphere_app_server { 'AppServer01':
  ensure       => 'present',
  node         => 'appNode01',
  dmgr_profile => 'PROFILE_DMGR_001',
  profile_base => '/opt/IBM/WebSphere/AppServer/profiles',
  user         => 'webadmins',
}
```

#### Parameters

##### `ensure`

Valid values: `present`, `absent`

Defaults to `true`.  Specifies whether this application server should exist or
not.

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
