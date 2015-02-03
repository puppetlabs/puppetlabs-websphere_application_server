### Defined Type: `websphere::package`

This defined type is essentially a _wrapper_ for the `ibm_pkg` type provided
by the [IBM Installation Manager](https://github.com/joshbeard/puppet-ibm_installation_manager)
module.

It handles the installation of IBM packages and the ownership of the install
locations.

While IBM Installation Manager does allow installing as a non-root user, this
module does not support that use-case.  When installing as non-root, package
metadata is located in a non-predictable location, and ultimately, this data
could be located in several locations.  That said, this module will install
packages as root.  However, it's often desirable to modify the _ownership_ of
the installation post-install.  This defined type also wraps the
`websphere::ownership` defined type to ensure the installation is owned as
desired.

This defined type is used by the `websphere::instance` defined type to manage
the installation of WebSphere instances.

A use-case for this defined type to an end-user is to install add-ons or
FixPacks.

#### Example

```puppet
## Install the 8.5.5.4 FixPack
websphere::package { 'Websphere_8554_fixpack':
  ensure     => 'present',
  package    => 'com.ibm.websphere.NDTRIAL.v85',
  version    => '8.5.5004.20141119_1746',
  repository => '/vagrant/ibm/FP04/repository.config',
  target     => '/opt/IBM/WebSphere/AppServer',
  user       => 'webadmin',
  group      => 'webadmins',
}

## Java7 installation
websphere::package { 'Websphere85_Java7':
  ensure     => 'present',
  package    => 'com.ibm.websphere.IBMJAVA.v71',
  version    => '7.1.2000.20141116_0823',
  repository => '/mnt/myorg/ibm/java7/repository.config',
  target     => '/opt/IBM/WebSphere/AppServer',
  user       => 'webadmin',
  group      => 'webadmins',
}
```

#### Parameters

##### `ensure`

Specifies the state of the package.  Valid values are `present` and `absent`

Defaults to `present`

##### `target`

The full path to where this package should be installed to.

Example: `/opt/IBM/WebSphere85/AppServer`

##### `package`

The IBM package name to install.

This is the _first_ part (before the first underscore) of IBM's full package
name.  For example, a full name from IBM looks like:
"com.ibm.websphere.NDTRIAL.v85_8.5.5000.20130514_1044".  The package name is
the first part of that.  In this example, "com.ibm.websphere.NDTRIAL.v85"

This corresponds to the repository metadata provided with IBM packages.

This parameter is required if a response file is not provided.

##### `version`

The IBM package version to install.

This is the _second_ part (after the first underscore) of IBM's full package
name.  For example, a full name from IBM looks like:
"com.ibm.websphere.NDTRIAL.v85_8.5.5000.20130514_1044".  The package version is
the second part of that.  In this example, "8.5.5000.20130514_1044"

This corresponds to the repository metadata provided with IBM packages.

This parameter is required if a response file is not provided.

##### `repository`

The full path to the installation repository file to install WebSphere from.
This should point to the location that the IBM package is extracted to.

When extracting an IBM package, a `repository.config` is provided in the base
directory.

Example: `/mnt/myorg/was/repository.config`

This parameter is required unless a response file is provided.  If a response
file is provided, it should contain repository information.

##### `response`

Specifies the full path to a response file to use for installation.  It is the
user's responsibility to have a response file created and available for
installation.

Typically, a response file will include, at a minimum, a package name, version,
target, and repository information.

This is optional. However, refer to the `target`, `package`, `version`, and
`repository` parameters.

##### `options`

Specifies options that will be _appended_ to the base set of options.

When using a response file, the base options are:
`input /path/to/response/file`

When not using a response file, the base set of options are:
`install ${package}_${version} -repositories ${repository} -installationDirectory ${target} -acceptLicense`

##### `imcl_path`

The full path to the `imcl` tool provided by the IBM Installation Manager.

The IBM default is `/opt/IBM/InstallationManager/eclipse/tools/imcl`

This will attempt to be auto-discovered by the `ibm_pkg` provider, which
parses IBM's data file in `/var/ibm` to determine where InstallationManager
is installed.

You can probably leave this blank unless `imcl` was not auto discovered.

##### `chown`

Boolean. Specifies whether the ownership should be managed post-install of the
`target`.

This will ensure all files and directories under `target` are owned/grouped
according to the `user` and `group` parameters.

Defaults to `true`.

##### `user`

Specifies the user that should "own" this installation.  This is only relevant
if `chown` is set to `true`.  All files and directories under `target` will
be owned by this user.

Defaults to `$::websphere::user`, referring to whatever user was provided when
declaring the base `websphere` class.

##### `group`

Specifies the group that should "own" this installation.  This is only relevant
if `chown` is set to `true`.  All files and directories under `target` will
be owned by this group.

Defaults to `$::websphere::group`, referring to whatever group was provided
when declaring the base `websphere` class.
