### Defined Type: `websphere::cluster`

This defined type is used for managing WebSphere clusters in a cell.

This defined type is intended to be declared by a DMGR server.

Essentially, this is just a wrapper for our native Ruby types, but it makes
it a little easier and abstracted for the end user.

This defined type will manage the existence of a cluster using the
[websphere_cluster](../types/websphere_cluster.md) type.

Optionally, it can also be used to _collect_ cluster members that were
_exported_. See Puppet's
[exported resources](https://docs.puppetlabs.com/puppet/latest/reference/lang_exported.html)
documentation for details on exported resources and collecting them.

#### Example

```puppet
# Declared on a DMGR
websphere::cluster { 'MyCluster01':
  ensure       => 'present',
  profile_base => '/opt/IBM/WebSphere/AppServer/profiles',
  dmgr_profile => 'PROFILE_DMGR_001',
  cell         => 'CELL_01',
  user         => 'webadmin',
}
```

#### Parameters

##### `ensure`

Specifies whether this cluster should exist or not.  Valid values are `present`
and `absent`.

Defaults to `present`

##### `profile_base`

Required. Specifies the full path to where WebSphere _profiles_ are stored.

The IBM default is `/opt/IBM/WebSphere/AppServer/profiles`

##### `dmgr_profile`

Required. The DMGR profile that this cluster should be created under. The
`wsadmin` tool is used from this profile.

Example: `PROFILE_DMGR_01`

##### `cell`

Required. The cell that this cluster should be created under.

##### `cluster`

The name of the cluster to manage.  Defaults to the resource title.

##### `collect_members`

Boolean. Defaults to `true`.

Specifies whether _exported_ resources relating to WebSphere clusters should
be _collected_ by this instance of the defined type.

If true, `websphere::cluster::member`, `websphere_cluster_member`, and
`websphere_cluster_member_service` resources will be _collected_ that match
this __cell__.

The use case for this is so application servers, for instance, can export
themselves as a cluster member in a certain cell.  When this defined type is
evaluated by a DMGR, those can automatically be collected.

##### `dmgr_host`

The resolvable hostname for the DMGR that this cluster exists on.  This is
needed for collecting cluster members.  Defaults to `$::fqdn`

##### `user`

The user that should run the `wsadmin` commands.  Defaults to
`$::websphere::user`
