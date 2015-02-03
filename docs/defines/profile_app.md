### Defined Type: `websphere::profile::appserver`

This defined type manages a WebSphere application server profile. At a minimum,
it manages the creation of the profile and the ownership of the profile data.

It also _collects_ exported federation data that a specified DMGR host
exported in order to federate.

Optionally, it can manage SDK versions via the websphere_sdk type.

It also manages the profile "service" (startManager.sh)

#### Example

```puppet
websphere::profile::appserver { 'PROFILE_APP_001':
  instance_base  => '/opt/IBM/WebSphere/AppServer',
  profile_base   => '/opt/IBM/WebSphere/AppServer/profiles',
  template_path  => '/opt/IBM/WebSphere/AppServer/profileTemplates/managed',
  dmgr_host      => 'dmgr.example.com',
  cell           => 'CELL_01',
  node_name      => 'appNode01',
  manage_sdk     => true,
  sdk_name       => '1.7.1_64',
  manage_service => true,
  user           => 'webadmin',
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

Required.  The cell that this application server should federate with.  For
example, `CELL_01`

##### `node_name`

Required.  The name for this "node".  For example, `appNode01`

##### `profile_name`

String. Defaults to the resource title (`$title`)

The name of the profile.  The directory that gets created will be named this.

Example: `PROFILE_APP_01` or `appProfile01`. Recommended to keep this
alpha-numeric.

##### `user`

String. Defaults to `$::websphere::user`

The user that should "own" this profile.

##### `group`

String. Defaults to `$::websphere::group`

The group that should "own" this profile.

##### `dmgr_host`

String. Defaults to `$::fqdn`

The address used to connect to the DMGR host.

##### `dmgr_port`

String. The SOAP port that should be used for federation.  You normally don't
need to specify this, as it's handled by exporting and collecting resources.

##### `template_path`

String. Must be an absolute path.  Defaults to
`${instance_base}/profileTemplates/app`

Should point to the full path to profile templates for creating the profile.

##### `options`

String. Defaults to `-create -profileName ${profile_name} -profilePath
${profile_base}/${profile_name} -templatePath ${_template_path} -nodeName
${node_name} -hostName ${::fqdn} -federateLater true -cellName standalone`

These are the options that are passed to `manageprofiles.sh` to create the
profile.

If you specify a value for `options`, none of the defaults will be used.

For application servers, the default cell name will be `standalone`, which is
intentional.  Upon federation (which we aren't doing as part of the profile
creation), the application server will federate with the specified cell.

##### `manage_federation`

Boolean. Defaults to `true`

Specifies whether federation should be managed by this defined type or not. If
not, the user is responsible for federation.

The `websphere_federate` type is used to handle the federation.

Federation, by default, requires a data file to have been exported by the DMGR
host and collected by the application server.  This defined type will collect
any _exported_ datafiles that match the DMGR host and cell.

##### `manage_service`

Boolean. Defaults to `true`. Specifies whether the service for the app profile
should be managed by this defined type instance.  In IBM terms, this is
`startNode.sh` and `stopNode.sh`

If set to `false`, the service should be managed via the
`websphere::profile::service` defined type by the user.

##### `manage_sdk`

Boolean. Defaults to `false`. Specifies whether SDK versions should be managed
by this defined type instance or not.  Essentially, when managed here, it will
set the default SDK for servers created under this profile.

This is only relevant if `manage_federation` is `true`.

##### `sdk_name`

String. The SDK name to set if `manage_sdk` is `true`.  This parameter is
_required_ if `manage_sdk` is true.  By default, it has no value set.

Example: `1.71_64`

Refer to the details for the `websphere_sdk` resource type for more
information.

This is only relevant if `manage_federation` and `manage_sdk` is `true`

