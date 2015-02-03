### Defined Type: `websphere::instance`

Manages an _installation_ of WebSphere.

This module was designed to support multiple installations of WebSphere to
different locations.  This defined type is intended to handle the base
installation.

This defined type can optionall manage a user and group that differs from what
is declared with the base `websphere` class.  For example, if you wanted a
particular installation to be "owned" by a different user.

This defined type manages the installation of WebSphere via the
`websphere::package` defined type.  A base directory for WebSphere profiles
is managed and a fact is populated with installation information.

#### Example

```puppet
## Manage an instance of WebSphere 8.5
websphere::instance { 'WebSphere85':
  target       => '/opt/IBM/WebSphere/AppServer',
  package      => 'com.ibm.websphere.NDTRIAL.v85',
  version      => '8.5.5000.20130514_1044',
  profile_base => '/opt/IBM/WebSphere/AppServer/profiles',
  repository   => '/mnt/myorg/was/repository.config',
  user         => 'webadmin',
  group        => 'webadmins',
}
```

Example when used in conjunction with the base class:

```puppet
class { 'websphere':
  base_dir => '/opt/IBM',
  user     => 'webadmin',
  group    => 'webadmins',
}

## Install with a response file
websphere::instance { 'WebSphere85':
  response_file => '/mnt/myorg/was/was85_response.xml',
}
```

#### Parameters

##### `base_dir`

Default is `$::websphere::base_dir`, as in, it will default to the value
of `base_dir` that is specified when declaring the base class `websphere`.

This should point to the base directory that WebSphere instances should be
installed to.  IBM's default is `/opt/IBM`

You normally don't need to specify this parameter.

##### `target`

The full path to where _this_ instance should be installed to.  The IBM default
is '/opt/IBM/WebSphere/AppServer'

The module default for `target` is "${base_dir}/${title}/AppServer", where
`title` refers to the title of the resource.

Example: `/opt/IBM/WebSphere85/AppServer`

##### `package`

The IBM package name to install for the base WebSphere installation.

This is the _first_ part (before the first underscore) of IBM's full package
name.  For example, a full name from IBM looks like:
"com.ibm.websphere.NDTRIAL.v85_8.5.5000.20130514_1044".  The package name is
the first part of that.  In this example, "com.ibm.websphere.NDTRIAL.v85"

This corresponds to the repository metadata provided with IBM packages.

This parameter is required if a response file is not provided.

##### `version`

The IBM package version to install for the base WebSphere installation.

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

##### `response_file`

Specifies the full path to a response file to use for installation.  It is the
user's responsibility to have a response file created and available for
installation.

Typically, a response file will include, at a minimum, a package name, version,
target, and repository information.

This is optional. However, refer to the `target`, `package`, `version`, and
`repository` parameters.

##### `install_options`

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

##### `profile_base`

Specifies the full path to where WebSphere _profiles_ will be stored.

The IBM default is `/opt/IBM/WebSphere/AppServer/profiles`

The module default is `${target}/profiles`

##### `manage_user`

Boolean. Specifies whether this _instance_ should manage the user specififed
by the `user` parameter.

Defaults to `false`.

A typical use-case would be to specify the user via the base class `websphere`
and let it manage it.

If this particular instance of WebSphere needs a different user, you may do
so here.


##### `manage_group`

Boolean. Specifies whether this _instance_ should manage the group specififed
by the `group` parameter.

Defaults to `false`.

A typical use-case would be to specify the group via the base class `websphere`
and let it manage it.

If this particular instance of WebSphere needs a different group, you may do
so here.

##### `user`

Specifies the user that should "own" this instance of WebSphere.

Defaults to `$::websphere::user`, referring to whatever user was provided when
declaring the base `websphere` class.

##### `group`

Specifies the group that should "own" this instance of WebSphere.

Defaults to `$::websphere::group`, referring to whatever group was provided
when declaring the base `websphere` class.

##### `user_home`

Specifies the home directory for the `user`.  This is only relevant if you're
managing the user _with this instance_ (e.g. not via the base class).  So if
`manage_user` is `true`, this is relevant.

Defaults to `$target`

