### Type: `websphere_cluster`

Manages the creation or removal of WebSphere server clusters.

#### Example

```puppet
websphere_cluster { 'MyCluster01':
  ensure       => 'present',
  dmgr_profile => 'PROFILE_DMGR_001',
  profile_base => '/opt/IBM/WebSphere/AppServer/profiles',
  user         => 'webadmins',
}
```

#### Parameters

##### `ensure`

Valid values: `present`, `absent`

Defaults to `true`.  Specifies whether this cluster should exist or not.

##### `name`

The name of the cluster to manage. Defaults to the resource title.

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
