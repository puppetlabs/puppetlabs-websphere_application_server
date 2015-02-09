### Type: `websphere_cluster_member_service`

Manages the a WebSphere cluster member's service.

#### Example

```puppet
websphere_cluster_member_service { 'AppServer01':
  ensure       => 'running',
  cell         => 'CELL_01',
  cluster      => 'MyCluster01',
  node         => 'appNode01',
  dmgr_profile => 'PROFILE_DMGR_001',
  profile_base => '/opt/IBM/WebSphere/AppServer/profiles',
  node         => 'appNode01',
  user         => 'webadmins',
}
```

#### Parameters

##### `ensure`

Valid values: `running` or `stopped`

Defaults to `running`.  Specifies whether the service should be running or not.

##### `cell`

Required. The name of the cell that the cluster member belongs to.

##### `cluster`

Required. The cluster that the cluster member belongs to.

##### `name`

The name of the cluster member that this service belongs to.  Defaults to the
resource title.

##### `node`

Required. The name of the _node_ that this cluster member is on. Refer to the
`websphere_node` type for managing the creation of nodes.

##### `dmgr_profile`

Required. The name of the DMGR profile that this cluster member is running
under.

Examples: `PROFILE_DMGR_01` or `dmgrProfile01`

##### `profile_base`

Required. The full path to the profiles directory where the `dmgr_profile` can
be found.  The IBM default is `/opt/IBM/WebSphere/AppServer/profiles`

##### `user`

Optional. The user to run the `wsadmin` command as. Defaults to "root"

##### `dmgr_host`

The DMGR host to add this cluster member to.

This is required if you're exporting the cluster member for a DMGR to
collect.  Otherwise, it's optional.

##### `wsadmin_user`

Optional. The username for `wsadmin` authentication if security is enabled.

##### `wsadmin_pass`

Optional. The password for `wsadmin` authentication if security is enabled.
