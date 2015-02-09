### Defined Type: `websphere::ihs::server`

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
websphere::ihs::server { 'josh_test':
  target      => "${ibm_base_dir}/HTTPServer85",
  log_dir     => "/opt/log/websphere/httpserver",
  plugin_dir  => "${ibm_base_dir}/Plugins85/config/josh_test",
  plugin_base => "${ibm_base_dir}/Plugins85",
  cell        => $dmgr_cell,
  config_file => '/opt/was/IBM/HTTPServer85/conf/httpd_josh_test.conf',
  access_log  => '/opt/log/websphere/httpserver/access_log',
  error_log   => '/opt/log/websphere/httpserver/error_log',
  listen_port => '10080',
}
```

#### Parameters

##### `target`

Required. Specifies the full path to the IHS installation that this server
should belong to.  For example, `/opt/IBM/HTTPServer`

##### `httpd_config`

Specifies the full path to the HTTP configuration file to manage.

Defaults to `${target}/conf/httpd_${title}.conf`

##### `user`

The user that should "own" and run this server instance.  The service will
be managed as this user. This also corresponds to the "User" option in the
HTTP configuration.

##### `group`

The group that should "own" and run this server instance.  This also
corresponds to the "Group" option in the HTTP configuration.

##### `docroot`

Specifies the full path to the document root for this server instance.

Defaults to `${target}/htdocs`

##### `instance`

This currently doesn't do anything.  It defaults to the resource's title.

##### `httpd_config_template`

Specifies a Puppet-readable location for a template to use for the HTTP
configuration.  One is provided, but this allows you to use your own custom
template.

Defaults to `${module_name}/ihs/httpd.conf.erb`

##### `timeout`

Specifies the value for `Timeout`

Defaults to `300`

##### `max_keep_alive_requests`

Specifies the value for `MaxKeepAliveRequests`

Defaults to `100`

##### `keep_alive`

Specifies the value for `KeepAlive`

Valid values are `On` or `Off`

Defaults to `On`

##### `keep_alive_timeout`

Specifies the value for `KeepAliveTimeout`

Defaults to `10`

##### `thread_limit`

Specifies the value for `ThreadLimit`

Defaults to `25`

##### `server_limit`

Specifies the value for `ServerLimit`

Defaults to `64`

##### `start_servers`

Specifies the value for `StartServers`

Defaults to `1`

##### `max_clients`

Specifies the value for `MaxClients`

Defaults to `600`

##### `min_spare_threads`

Specifies the value for `MinSpareThreads`

Defaults to `25`

##### `max_spare_threads`

Specifies the value for `MaxSpareThreads`

Defaults to `75`

##### `threads_per_child`

Specifies the value for `ThreadsPerChild`

Defaults to `25`

##### `max_requests_per_child`

Specifies the value for `MaxRequestsPerChild`

Defaults to `25`

##### `limit_request_field_size`

Specifies the value for `LimitRequestFieldsize`

Defaults to `12392`

##### `listen_address`

Specifies the address for the `Listen` HTTP option.  Can be an asterisk to
listen on everything.

Defaults to `$::fqdn`

##### `listen_port`

Specifies the port for the `Listen` HTTP option.

Defaults to `10080`

##### `server_admin_email`

Specifies the value for the `ServerAdmin` e-mail address.

Defaults to `user@example.com`

##### `server_name`

Specifies the value for the `ServerName` HTTP option.  Typically, an HTTP
ServerName option will look like:

```
ServerName host:port
```

This specifies the _host_ part of that.

Defaults to `$::fqdn`

##### `server_listen_port`

Specifies the port value for the `ServerName` HTTP option. Typically, an
HTTP ServerName option will look like:

```
ServerName host:port
```

This specifies the _port_ part of that.  Often, this will be the same as the
`listen_port`, but there are cases where this would differ.  For example, if
this server instance is behind a load balancer or VIP.

##### `node_os`

Specifies the operating system for this server.  This is used for the DMGR
to create an _unmanaged_ node for this server.

By default, this will be figured out based on the `$::kernel` fact.

We currently only support "aix" and "linux"

##### `pid_file`

Specifies the base filename for a PID file.  Defaults to the resource's
title.

This isn't the full path - just the filename.

##### `replace_config`

Boolean.  Specifies whether Puppet should replace this server's HTTP
configuration once it's present.  Basically, if the file doesn't exist, Puppet
will create it.  If this parameter is set to `true`, Puppet will also make
sure that configuration file matches what we describe.  If this value is
`false`, Puppet will ignore the file's contents.

You should probably leave this set to `true` and manage the config file through
Puppet exclusively.

##### `directory_index`

Specifies the `DirectoryIndex` for this instance.

Should be a string that has space-separated filenames.

Defaults to `index.html index.html.var`

##### `log_dir`

Specifies the full path to where access/error logs should be stored.

Defaults to `${target}/logs`

##### `access_log`

The filename for the access log.  Defaults to `access_log`

##### `error_log`

The filename for the error log.  Defaults to `error_log`

##### `export_node`

Boolean. Specifies whether a `websphere_node` resource should be exported.
This is intended to be used for DMGRs to collect to create an _unmanaged_
node.

Defaults to `true`

##### `export_server`

Boolean. Specifies whether a `websphere_web_server` resource should be
exported for this server.

This is intended to be used for a DMGR to collect to create a web server
instance.

Defaults to `true`

##### `node`

Specifies the node name to use for creation on a DMGR.

Defaults to `$::fqdn`

Required if `export_node` is `true`

##### `node_hostname`

Specifies the resolvable address for this server for creating the node.

The DMGR host needs to be able to reach this server at this address.

Defaults to `$::fqdn`

##### `cell`

The cell that this node should be a part of.

Required if `export_node` is `true`

##### `admin_username`         = 'httpadmin',

Specifies the administrator username that a DMGR can query and manage this
server with.

Defaults to `httpadmin`

This is required if `export_server` is true.

##### `admin_password          = 'password',

Specifies the administrator password that a DMGR can query and manage this
server with.

Defaults to `password`

This is required if `export_server` is true.

##### `plugin_base`

Specifies the full path to the plugin base directory.

Defaults to `/opt/IBM/Plugins`

##### `propagate_keyring`

Boolean. Specifies whether the plugin keyring should be propagated from the
DMGR to this server once the web server instance is created on the DMGR.

Defaults to `true`

This is only relevant if `export_server` is `true`

##### `dmgr_host`

The DMGR host to add this server to.

This is required if you're exporting the server for a DMGR to
collect.  Otherwise, it's optional.
