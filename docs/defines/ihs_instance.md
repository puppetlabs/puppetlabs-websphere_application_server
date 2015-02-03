### Defined Type: `websphere::ihs::instance`

This defined type is used to manage IBM HTTPServer (IHS) installations.

Eventually, this functionality could likely be split into its own module. For
now, though, we offer basic management of IHS instances in the context of
WebSphere.

#### Example

```puppet
websphere::ihs::instance { 'HTTPServer85':
  target           => '/opt/IBM/HTTPServer',
  package          => 'com.ibm.websphere.IHSILAN.v85',
  version          => '8.5.5000.20130514_1044',
  repository       => "/mnt/myorg/ihs/repository.config",
  install_options  => '-properties user.ihs.httpPort=8008',
  user             => 'webadmin',
  group            => 'webadmins',
  manage_user      => false,
  manage_group     => false,
  log_dir          => '/opt/log/websphere/httpserver',
  admin_username   => 'httpadmin',
  admin_password   => 'password',
  webroot          => '/opt/web',
}
```

#### Parameters

##### `base_dir`

Specifies the full path to the _base_ directory that IHS and IBM instances
should be installed to.  The IBM default is `/opt/IBM`

The module default is `$::websphere::base_dir`

##### `target`

The target directory to where this instance of IHS should be installed to.

The IBM default is `/opt/IBM/HTTPServer`

The module default is `${base_dir}/${title}`, where `$title` is the title of
this resource.

So if we declared it as such:

```puppet
websphere::ihs::instance { 'HTTPServer85': }
```

And assumed IBM defaults, it would be installed to `/opt/IBM/HTTPServer85`

##### `package`

The IBM package name to install for the HTTPServer installation.

This is the _first_ part (before the first underscore) of IBM's full package
name.  For example, a full name from IBM looks like:
`com.ibm.websphere.IHSILAN.v85_8.5.5000.20130514_1044`.  The package name is
the first part of that.  In this example, `com.ibm.websphere.IHSILAN.v85`

This corresponds to the repository metadata provided with IBM packages.

This parameter is required if a response file is not provided.

##### `version`

The IBM package version to install for the HTTPServer installation.

This is the _second_ part (after the first underscore) of IBM's full package
name.  For example, a full name from IBM looks like:
`com.ibm.websphere.IHSILAN.v85_8.5.5000.20130514_1044`.  The package version is
the second part of that.  In this example, `8.5.5000.20130514_1044`

This corresponds to the repository metadata provided with IBM packages.

This parameter is required if a response file is not provided.

##### `repository`

The full path to the installation repository file to install IHS from.
This should point to the location that the IBM package is extracted to.

When extracting an IBM package, a `repository.config` is provided in the base
directory.

Example: `/mnt/myorg/ihs/repository.config`

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

Specifies the user that should "own" this instance of IHS.

Defaults to `$::websphere::user`, referring to whatever user was provided when
declaring the base `websphere` class.

##### `group`

Specifies the group that should "own" this instance of IHS.

Defaults to `$::websphere::group`, referring to whatever group was provided
when declaring the base `websphere` class.

##### `user_home`

Specifies the home directory for the `user`.  This is only relevant if you're
managing the user _with this instance_ (e.g. not via the base class).  So if
`manage_user` is `true`, this is relevant.

Defaults to `$target`

##### `log_dir`

Specifies the full path to where log files should be placed.

In `websphere::ihs::instance`, this only manages the directory.

Defaults to `${target}/logs`

##### `webroot`

Specifies the full path to where individual document roots will be stored.

This is basically the base directory for doc roots.

In `websphere::ihs::instance`, this only manages the directory.

Defaults to `/opt/web`

##### `admin_listen_port`

Specifies the port that the IHS administration is listening on.

Defaults to `8008`, which is IBM's default.

##### `adminconf_template`

Specifies an ERB (Puppet) template to use for the resulting `admin.conf` file.

By default, the module includes one.  The value of this parameter should refer
to a Puppet-accessible source, like `$module_name/template.erb`

The default value is `${module_name}/ihs/admin.conf.erb`

##### `replace_config`

Boolean. Specifies whether Puppet should continue to manage the `admin.conf`
configuration after it's already placed it.

Basically, if the file does not exist, Puppet will create it accordingly. If
it does already exist, Puppet will not replace it.

This defaults to `true`.  It's strongly recommended to leave it alone and let
Puppet manage it exclusively.

This parameter might yield unexpected results.  If IBM provides an `admin.conf`
file by default, then setting this parameter to `false` will cause the module
to _never_ manage the file.

##### `server_name`

Specifies the server's name that will be used in the HTTP configuration for
the `ServerName` option for the admin configuration.

Defaults to `$::fqdn`

##### `manage_htpasswd`

Boolean. Specifies whether this defined type should manage the `htpasswd`
authentication for the administrator credentials.  These are used by WebSphere
consoles to query and manage an IHS instance.

If `true`, the `htpasswd` utility will be used to manage the credentials.

If `false`, the user is responsible for configuring this.

##### `admin_username`

String. The administrator username that a WebSphere Console can use for
authentication to query and manage this IHS instance.

If `manage_htpasswd` is `true`, the `htpasswd` utility will be used to manage
the credentials.

Defaults to `httpadmin`

##### `admin_password`

String. The administrator password that a WebSphere Console can use for
authentication to query and manage this IHS instance.

If `manage_htpasswd` is `true`, the `htpasswd` utility will be used to manage
the credentials.

Defaults to `password`
