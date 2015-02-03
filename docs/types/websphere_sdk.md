### Type: `websphere_sdk`

Manages the SDK/JDK settings for WebSphere resources.

This doesn't manage the _installation_ of them, but manages _which_ SDK a
particular WebSphere server/node uses.

Under the hood, the included provider is running `managesdk.sh`

#### Example

```puppet
websphere_sdk { 'SDK Version 1.7':
  profile             => 'PROFILE_APP_001',
  server              => 'all',
  sdkname             => '1.7.1_64',
  instance_base       => '/opt/IBM/WebSphere/AppServer',
  new_profile_default => '1.7.1_64',
  command_default     => '1.7.1_64',
  node                => 'nodeagent',
  user                => 'webadmins',
}
```

#### Parameters

##### `ensure`

Valid values: `present`, `absent`

Defaults to `true`.  Specifies whether this application server should exist or
not.

##### `server`

The server in the scope for this variable.

This can be a specific server or `all` to affect all servers

`all` corresponds to the `managesdk.sh` option `-enableServers`

##### `profile`

The profile to modify.

Specify `all` for all profiles. `all` corresponds to the `managesdk.sh`
option `-enableProfileAll`

A specific profile name can also be provided. Example: `PROFILE_APP_001`.
This corresponds to `managesdk.sh` options `-enableProfile -profileName`

##### `name`

The name of the resource. This is only used for Puppet to identify
the resource and has no influence over the commands used to make
modifications or query SDK versions.

##### `sdkname`

The name of the SDK to modify. Example: `1.7.1_64`

##### `instance_base`

The base directory that WebSphere is installed.

This is used to the `managesdk` command can be found.

Example: `/opt/IBM/WebSphere/AppServer/`

##### `command_default`

Manages the SDK name that script commands in the
app_server_root/bin, app_client_root/bin, or plugins_root/bin directory
are enabled to use when no profile is specified by the command and when
no profile is defaulted by the command.

##### `new_profile_default`

Manages the SDK name that is currently configured for all profiles
that are created with the manageprofiles command. The -sdkname parameter
specifies the default SDK name to use. The sdkName value must be an SDK
name that is enabled for the product installation.

##### `node`

The name of the _node_ to create this server on.  Refer to the
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
