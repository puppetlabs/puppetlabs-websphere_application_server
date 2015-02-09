### Type: `websphere_node`

Manages the an "unmanaged" WebSphere node in a cell.  For example, adding an
IHS server to a cell.

In `wsadmin` terms using _jython_, this basically translates to the
`AdminTask.createUnmanagedNode` task.

#### Example

```puppet
websphere_node { 'IHS Server':
  node         => 'ihsServer01',
  os           => 'linux',
  hostname     => 'ihs01.example.com',
  cell         => 'CELL_01',
  dmgr_profile => 'PROFILE_DMGR_01',
  profile_base => '/opt/IBM/WebSphere/AppServer/profiles',
  user         => 'webadmins',
}
```

__Exported resource example__

An IHS server can export a resource:

```puppet
@@websphere_node { $::fqdn:
  node      => $::fqdn,
  os        => 'linux',
  hostname  => $::fqdn,
  cell      => 'CELL_01',
  dmgr_host => 'dmgr01.example.com',
```

A DMGR can collect it and append its profile information to it:

```puppet
Websphere_node <<| cell == 'CELL_01' |>> {
  dmgr_profile => 'PROFILE_DMGR_01',
  profile_base => '/opt/IBM/Websphere/AppServer/profiles',
  user         => 'webadmins',
}
```

#### Parameters

##### `ensure`

Valid values: `present`, `absent`

Defaults to `true`.  Specifies whether this node should exist or not.

##### `name`

The name of the node to add. Defaults to the resource's title.

##### `hostname`

The hostname that the server can be reached at - probably the FQDN.

##### `node`

The name of the node manage.  Synonomous with `name`.  Defaults to the value
of `name`.  I'm not sure why both exist - name is actually only used to
identify the Puppet resource, but the `node` parameter value is what gets
translated into `wsadmin` arguments.

##### `os`

Required. The Operating System of the node you're adding.

Valid values are: `linux` and `aix`

Defaults to `linux`

##### `cell`

The cell that this node should belong to.  This has no influence over the
`wsadmin` command, but is used for instances where exported/collected
resources are used.  For example, if an IHS server _exports_ a `websphere_node`
resource and a DMGR collects it, it should collect based on the cell it's
managing.

##### `dmgr_profile`

Required. The name of the DMGR profile to create this node under.

Examples: `PROFILE_DMGR_01` or `dmgrProfile01`

##### `profile_base`

Required. The full path to the profiles directory where the `dmgr_profile` can
be found.  The IBM default is `/opt/IBM/WebSphere/AppServer/profiles`

##### `dmgr_host`

The DMGR host to add this node to.

This is required if you're exporting the node for a DMGR to
collect.  Otherwise, it's optional.

##### `user`

Optional. The user to run the `wsadmin` command as. Defaults to "root"

##### `wsadmin_user`

Optional. The username for `wsadmin` authentication if security is enabled.

##### `wsadmin_pass`

Optional. The password for `wsadmin` authentication if security is enabled.
