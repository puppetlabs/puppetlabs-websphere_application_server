### Defined Type: `websphere::ownership`

This defined type is used to manage the user and group ownership of a target
directory.

While IBM Installation Manager does allow installing as a non-root user, this
module does not support that use-case.  When installing as non-root, package
metadata is located in a non-predictable location, and ultimately, this data
could be located in several locations.  That said, this module will install
packages as root.  However, it's often desirable to modify the _ownership_ of
the installation post-install.

#### Example

```puppet
websphere::ownership { 'some_dir':
  user  => 'webadmin',
  group => 'webadmins',
  path  => '/opt/IBM/WebSphere',
}
```

#### Parameters

##### `path`

The full path to the directory that ownership should be managed. Defaults to
the resource title.

Example: '/opt/IBM/WebSphere'

##### `user`

Required. Specifies the user that should "own" this path.
All files and directories under `path` will be owned by this user.

##### `group`

Required. Specifies the group that should "own" this path.
All files and directories under `path` will be owned by this group.

