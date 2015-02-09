### Type: `websphere_web_server`

Manages WebSphere web servers in a cell.

Under the hood, the included provider is running `wsadmin`

#### Example

```puppet
websphere_web_server { 'MyServer01':
  node              => 'ihstest.example.com',
  cell              => 'CELL_01',
  admin_user        => 'httpadmin',
  admin_pass        => 'hunter2',
  plugin_base       => '/opt/IBM/Plugins',
  install_root      => '/opt/IBM/HTTPServer',
  config_file       => '/opt/IBM/HTTPServer/conf/myserver_httpd.conf',
  access_log        => '/opt/log/http/myserver_access.log',
  error_log         => '/opt/log/http/myserver_error.log',
  web_port          => '8080',
  propagate_keyring => true,
  dmgr_profile      => 'PROFILE_DMGR_01',
  profile_base      => '/opt/IBM/WebSphere/AppServer/profiles',
  user              => 'webadmins',
}
```

#### Parameters

##### `ensure`

Valid values: `present`, `absent`

Defaults to `true`.  Specifies whether this web server should exist or not.

##### `name`

The name of the web server to manage.  Defaults to the resource title.

##### `cell`

The cell that this web server belongs to.  This is used for managing instances
in a cell.  The DMGR uses this to identify which servers belong to it.

##### `node`

The name of the node to create this web server on.  Refer to the
`websphere_node` type for information on managing nodes.

##### `propagate_keyring`

Boolean.  Specifies whether the plugin keyring should be copied from the
DMGR to the server once created.  This only takes affect upon creation.

Defaults to `false`

##### `config_file`

The full path to the HTTP config file.  This is used for the DMGR to discover
the configuration file.

##### `template`

The template to use for creating the web server.  Defaults to `IHS`.

Other templates have not been tested and are not supported by this type.

##### `access_log`

The path to the access log.  This is for the DMGR to discover the access log.

##### `error_log`

The path to the error log.  This is for the DMGR to discover the error log.

##### `web_port`

Specifies the port that the HTTP instance is listening on.  Defaults to `80`

##### `install_root`

The full path to the _root_ of the IHS installation. The default (and the IBM
default) is `/opt/IBM/HTTPServer`

##### `protocol`

The protocol the HTTP instance is listening on.  HTTP or HTTPS.

Defaults to `HTTP`

##### `plugin_base`

The full path to the base directory for plugins on the HTTP server.

For example: `/opt/IBM/HTTPServer/Plugins`

##### `web_app_mapping`

Application mapping to the web server.  'ALL' or 'NONE'.

Defaults to 'NONE'

##### `admin_port`

String. The administration server port.  Defaults to `8008`

##### `admin_user`

Required. The administration server username.

##### `admin_pass`

Required. The administration server password.

##### `admin_protocol`

The protocol for administration.  'HTTP' or 'HTTPS'.  Defaults to 'HTTP'.

##### `dmgr_profile`

The DMGR profile that this web server should be managed under.  The `wsadmin`
tool will be found here.

Example: `dmgrProfile01` or `PROFILE_DMGR_001`

##### `profile_base`

Required. The full path to the profiles directory where the `profile` can
be found.  The IBM default is `/opt/IBM/WebSphere/AppServer/profiles`

##### `dmgr_host`

The DMGR host to add this web server to.

This is required if you're exporting the web server for a DMGR to
collect.  Otherwise, it's optional.

##### `user`

Optional. The user to run the `wsadmin` command as. Defaults to "root"

##### `wsadmin_user`

Optional. The username for `wsadmin` authentication if security is enabled.

##### `wsadmin_pass`

Optional. The password for `wsadmin` authentication if security is enabled.
