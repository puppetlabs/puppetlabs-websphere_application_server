### Type: `websphere_federate`

Manages the federation of WebSphere application servers with a cell.

By default, this resource expects that a data file will be available in
Puppet's `$vardir` containing information about the DMGR cell to federate
with.

By default, this module's `websphere::profile::dmgr` defined type will
_export_ a file resource containing this information.  The application servers
that have declared `websphere::profile::appserver` will _collect_ that
exported resource and place it under `${vardir}/dmgr_${dmgr_host}_${cell}.yaml`
For example: `/var/opt/lib/pe-puppet/dmgr_dmgr.example.com_cell01.yaml`  This
is all automatic behind the scenes.

To federate, the application server needs to know the DMGR SOAP port, which is
included in this exported/collected file.  Optionally, you may provide it as
a parameter value if you're using this resource type directly.

Essentially, the provider for this resource type executes `addNode.sh` to do
the federation.

#### Example

Federate the "PROFILE_APP_001" profile with a cell called "CELL_01" on the
DMGR host "dmgr01.example.com"

```puppet
websphere_federate { 'PROFILE_APP_001':
  cell         => 'CELL_01',
  profile_base => '/opt/IBM/WebSphere/AppServer/profiles',
  dmgr_host    => 'dmgr01.example.com',
  soap_port    => '8879',
  user         => 'webadmins',
}
```

#### Parameters

##### `ensure`

Valid values: `present`, `absent`

Defaults to `present`.  Specifies whether this application server profile
should be federated or not.  Executes `addNode.sh` or `removeNode.sh` under the
hood.

##### `cell`

Required. The name of the cell to federate with.

##### `node`

Required. The name of the _node_ to federate.

##### `profile`

Required. The name of the _profile_ to federate.

##### `profile_base`

Required. The full path to the profiles directory where the `profile` can
be found.  The IBM default is `/opt/IBM/WebSphere/AppServer/profiles`

##### `soap_port`

The DMGR SOAP port to connect to for federation.  This is only needed if a
data file has *not* been exported from the DMGR and if you're declaring this
resource manually.

##### `options`

Any custom options to pass to the `addNode.sh` or `removeNode.sh` commands
for federation or de-federation.

##### `user`

Optional. The user to run the `addNode.sh` or `removeNode.sh` command as.
Defaults to "root"

##### `username`

Optional. The username for `addNode.sh` authentication if security is enabled.

##### `password`

Optional. The password for `addNode.sh` authentication if security is enabled.
