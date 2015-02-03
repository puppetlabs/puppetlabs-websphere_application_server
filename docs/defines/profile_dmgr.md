### Defined Type: `websphere::profile::dmgr`

This defined type manages a DMGR profile. At a minimum, it manages the creation
of the profile and the ownership of the profile data.

It also exports a file resource that contains the SOAP port that's used for
Application Server federation.

Optionally, it can manage SDK versions via the websphere_sdk type.

It also manages the profile "service" (startManager.sh)

Optionally, it can collect exported websphere_node resources,
websphere_web_server resources, and websphere_jvm_log resources that were
exported from other systems. The collection of these resources is enabled by
default.

#### Example

```puppet
websphere::profile::dmgr { 'PROFILE_DMGR_001':
  instance_base => '/opt/IBM/WebSphere/AppServer',
  profile_base  => '/opt/IBM/WebSphere/AppServer/profiles',
  cell          => 'CELL_01',
  node_name     => 'NODE_DMGR_01',
  user          => 'webadmin',
  group         => 'webadmins',
}
```

#### Parameters

##### `instance_base`

Required. The full path to the _installation_ of WebSphere that this profile
should be created under.  The IBM default is `/opt/IBM/WebSphere/AppServer`

##### `profile_base`

Required. The full path to the _base_ directory of profiles.  The IBM default
is `/opt/IBM/WebSphere/AppServer/profiles`

##### `cell`

Required.  The cell name to create.  For example, `CELL_01`

##### `node_name`

Required.  The name for this "node".  For example, `dmgrNode01`

##### `profile_name`

String. Defaults to the resource title (`$title`)

The name of the profile.  The directory that gets created will be named this.

Example: `PROFILE_DMGR_01` or `dmgrProfile01`. Recommended to keep this
alpha-numeric.

##### `user`

String. Defaults to `$::websphere::user`

The user that should "own" this profile.

##### `group`

String. Defaults to `$::websphere::group`

The group that should "own" this profile.

##### `dmgr_host`

String. Defaults to `$::fqdn`

The address for this DMGR system.  Should be an address that other hosts can
connect to.

##### `template_path`

String. Must be an absolute path.  Defaults to `${instance_base}/profileTemplates/dmgr`

Should point to the full path to profile templates for creating the profile.

##### `options`

String. Defaults to `-create -profileName ${profile_name} -profilePath
${profile_base}/${profile_name} -templatePath ${_template_path} -nodeName
${node_name} -hostName ${::fqdn} -cellName ${cell}`

These are the options that are passed to `manageprofiles.sh` to create the
profile.

##### `manage_service`

Boolean. Defaults to `true`. Specifies whether the service for the DMGR profile
should be managed by this defined type instance.  In IBM terms, this is
`startManager.sh` and `stopManager.sh`

If set to `false`, the service should be managed via the
`websphere::profile::service` defined type by the user.

##### `manage_sdk`

Boolean. Defaults to `false`. Specifies whether SDK versions should be managed
by this defined type instance or not.  Essentially, when managed here, it will
set the default SDK for servers created under this profile.

##### `sdk_name`

String. The SDK name to set if `manage_sdk` is `true`.  This parameter is
_required_ if `manage_sdk` is true.  By default, it has no value set.

Example: `1.71_64`

Refer to the details for the `websphere_sdk` resource type for more
information.

##### `collect_nodes`

Boolean. Defaults to `true`.

Specifies whether to collect exported `websphere_node` resources.  This is
useful for instances where unmanaged servers export `websphere_node` resources
to dynamically add themselves to a cell.

Refer to the details for the `websphere_node` resource type for more
information.

##### `collect_web_servers`

Boolean. Defaults to `true`.

Specifies whether to collect exported `websphere_web_server` resources.  This
is useful for instances where IHS servers export `websphere_web_server`
resources to dynamically add themselves to a cell.

Refer to the details for the `websphere_web_server` resource type for more
information.

##### `collect_jvm_logs`

Boolean. Defaults to `true`.

Specifies whether to collect exported `websphere_jvm_log` resources.  This
is useful for instances where application servers export `websphere_jvm_log`
resources to manage their JVM logging properties.

Refer to the details for the `websphere_jvm_log` resource type for more
information.
