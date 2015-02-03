### Defined Type: `websphere::profile::service`

This defined type is used to manage the node service for WebSphere profiles.

By default, this defined type is declared from `websphere::profile::dmgr` and
`websphere::profile::appserver`, so you do not need to declare it yourself.

However, if you need more flexibility, you can declare it yourself (or not at
all).

#### Example

```puppet
websphere::profile::service { 'dmgrProfile01':
  type         => 'dmgr',
  profile_base => '/opt/IBM/WebSphere/AppServer/profiles',
  user         => 'webadmin',
}
```

#### Parameters

##### `type`

Required. Specifies the type of service.  Valid values are `dmgr` and `app`

DMGR profiles are managed via IBM's `startManager` and `stopManager` scripts.

Application servers (well, non-DMGR servers) are managed via the `startNode`
and `stopNode` scripts.

##### `profile_base`

Required. The full path to where profiles are stored.

The IBM default is `/opt/IBM/WebSphere/AppServer/profiles`

##### `profile_name`

The name of the profile that this service runs.  Defaults to the resource's
title.

Example: `PROFILE_APP_01`

##### `user`

The user to execute the service commands with.  For example, the `startNode.sh`
script.

Defaults to `root`.  Typically, the user will match whatever user "owns" the
instance.  Refer to the `user` parameter for the
`websphere::profile::appserver` and `websphere::profile::dmgr` types.

##### `ensure`

Specifies the state of the service.  Valid values are `running` and `stopped`

Defaults to `running`

##### `start`

Specifies a command to _start_ the service with.

This differs between DMGR hosts and Application Servers.

On a DMGR, the default is:

`/bin/su - ${user} -c '${profile_base}/${profile_name}/bin/startManager.sh -profileName ${profile_name}'`

On an application server, the default is:

`/bin/su - ${user} -c '${profile_base}/${profile_name}/bin/startNode.sh'`

##### `stop`

Specifies a command to _stop_ the service with.

This differs between DMGR hosts and Application Servers.

On a DMGR, the default is:

`/bin/su - ${user} -c '${profile_base}/${profile_name}/bin/stopManager.sh -profileName ${profile_name}'`

On an application server, the default is:

`/bin/su - ${user} -c '${profile_base}/${profile_name}/bin/stopNode.sh'`

##### `status`

Specifies a command to check the _status_ of the service with.

This differs between DMGR hosts and Application Servers.

On a DMGR, the default is:

`/bin/su - ${user} -c '${profile_base}/${profile_name}/bin/serverStatus.sh dmgr -profileName ${profile_name} | grep -q STARTED'`

On an application server, the default is:

`/bin/su - ${user} -c '${profile_base}/${profile_name}/bin/serverStatus.sh nodeagent -profileName ${profile_name} | grep -q STARTED'`

##### `restart`

Specifies a command to _restart_ the service with.

By default, we do not define anything.  Instead, Puppet will _stop_ the service
and _start_ the service to restart it.
