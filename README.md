# websphere_application_server

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with websphere_application_server](#setup)
    * [Beginning with websphere_application_server](#beginning-with-websphere_application_server)
3. [Usage](#usage)
    * [Creating a websphere_application_server instance](#creating-a-websphere_application_server-instance)
    * [Install FixPacks](#install-fixpacks)
    * [Creating Profiles](#creating-profiles)
    * [Creating a Cluster](#creating-a-cluster)
    * [Configuring the instance](#configuring-the-instance)
        * [Variables](#variables)
        * [JVM Logs](#jvm-logs)
        * [JDBC Providers and Datasources](#jdbc-providers-and-datasources)
    * [IHS](#ihs)
4. [Reference - Classes and Parameters](#reference)
    * [Classes](#classes)
    * [Defined Types](#defined-types)
    * [Types](#types)
    * [Facts](#facts)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Dependencies](#dependencies)
7. [Development and Contributing](#development-and-contributing)
   * [TODO](#todo)
   * [Contributors](#contributors)

## Description

Manages the deployment and configuration of [IBM WebSphere Application Server](http://www-03.ibm.com/software/products/en/was-overview). This module manages the following IBM Websphere cell types:

* Deployment Managers (DMGR)
* Application Servers
* IHS Servers

## Setup

### Beginning with websphere_application_server

To get started, declare the base class on any server that will use this module - DMGR, App Servers, or IHS.

```puppet
class { 'websphere_application_server':
  user     => 'webadmin',
  group    => 'webadmins',
  base_dir => '/opt/IBM',
}
```

## Usage

### Creating a websphere_application_server instance

The word "instance" used throughout this module basically refers to a complete installation of WebSphere Application Server.  Ideally, you'd just have a single instance of WebSphere on a given system.  This module, however, does offer the flexibility to have multiple installations.  This is useful for cases where you want two different major versions available (e.g. WAS 7 and WAS 8).

To install WebSphere using an installation zip:

**Note:** The example below assumes that the WebSphere installation zip file has been downloaded and extracted to `/mnt/myorg/was` and contains `repository.config`.

```puppet
websphere_application_server::instance { 'WebSphere85':
  target       => '/opt/IBM/WebSphere/AppServer',
  package      => 'com.ibm.websphere.NDTRIAL.v85',
  version      => '8.5.5000.20130514_1044',
  profile_base => '/opt/IBM/WebSphere/AppServer/profiles',
  repository   => '/mnt/myorg/was/repository.config',
}
```

To install WebSphere using a response file:

```puppet
websphere_application_server::instance { 'WebSphere85':
  response     => '/mnt/myorg/was/was85_response.xml',
  profile_base => '/opt/IBM/WebSphere/AppServer/profiles',
}
```

### Install FixPacks

It's common to install an IBM "FixPack" after the base installation.

In the following example the WebSphere 8.5.5.4 fixpack is installed onto the existing Websphere 8.5.5.0 installation from the above example. The `require` metaparameter is applied to enforce dependency ordering.

```puppet
ibm_pkg { 'WebSphere_8554':
  ensure        => 'present',
  package       => 'com.ibm.websphere.NDTRIAL.v85',
  version       => '8.5.5004.20141119_1746',
  target        => '/opt/IBM/WebSphere/AppServer',
  repository    => '/mnt/myorg/was_8554/repository.config',
  package_owner => 'wsadmin',
  package_group => 'wsadmins',
  require       => Websphere_application_server::Instance['WebSphere85'],
}
```
An example of installing Java 7 into the same Websphere installation as above:

```puppet
ibm_pkg { 'Java7':
  ensure        => 'present',
  package       => 'com.ibm.websphere.IBMJAVA.v71',
  version       => '7.1.2000.20141116_0823',
  target        => '/opt/IBM/WebSphere/AppServer',
  repository    => '/mnt/myorg/java7/repository.config',
  package_owner => 'wsadmin',
  package_group => 'wsadmins',
  require       => Websphere_application_server::Package['WebSphere_8554'],
}
```

### Creating Profiles

Once the base software is installed, a profile must be created. The profile is the runtime enironment.  A server can potentially have multiple profiles.  A DMGR profile is ultimately what defines a given "cell" in WebSphere.

In the following example, a DMGR profile, `PROFILE_DMGR_01` is created with associated cell and node_name. The `subscribe` metaparameter is used to set the relationship and ordering with the base installations.  Any changes to the base installation triggers a refresh to `websphere_application_server::profile::dmgr` if necessary.

```puppet
websphere_application_server::profile::dmgr { 'PROFILE_DMGR_01':
  instance_base => '/opt/IBM/WebSphere/AppServer',
  profile_base  => '/opt/IBM/WebSphere/AppServer/profiles',
  cell          => 'CELL_01',
  node_name     => 'dmgrNode01',
  subscribe     => [
    Ibm_pkg['Websphere_8554'],
    Ibm_pkg['Java7'],
  ],
}
```

When a DMGR profile is created, the module will use Puppet's *exported resources* to export a *file* resource that contains information needed for application servers to federate with it.  This includes the SOAP port and the host name (fqdn).

The DMGR profile will collect any exported `websphere_node`, `websphere_web_server`, and `websphere_jvm_log` resources by default.

An example of an Application Server profile:

```puppet
websphere_application_server::profile::appserver { 'PROFILE_APP_001':
  instance_base  => '/opt/IBM/WebSphere/AppServer',
  profile_base   => '/opt/IBM/WebSphere/AppServer/profiles',
  cell           => 'CELL_01',
  template_path  => '/opt/IBM/WebSphere/AppServer/profileTemplates/managed',
  dmgr_host      => 'dmgr.example.com',
  node_name      => 'appNode01',
  manage_sdk     => true,
  sdk_name       => '1.7.1_64',
}
```

### Creating a Cluster

Once profiles are created on the DMGR and an application server, a cluster can be created and an application servers can be added as a member of the cluster.

#### Associate the cluster with a DMGR profile:

```puppet
websphere_application_server::cluster { 'MyCluster01':
  profile_base => '/opt/IBM/WebSphere/AppServer/profiles',
  dmgr_profile => 'PROFILE_DMGR_01',
  cell         => 'CELL_01',
  require      => Websphere_application_server::Profile::Dmgr['PROFILE_DMGR_01'],
}
```

In this example, a cluster called `MyCluster01` will be created.  Provide the `profile_base` and `dmgr_profile` to specify where this cluster should be created.  Additionally, use the `require` metaparameter to set a relationship between the profile and the cluster. Ensure that the profile has been managed before attempting to manage the cluster.

#### Adding cluster members:

There are two ways to add cluster members.  The DMGR can explicitly declare each member or the members can export a resource to add themselves.

In the following example, a `websphere::cluster::member` resource is defined on the application server and exported.

```puppet
@@websphere_application_server::cluster::member { 'AppServer01':
  ensure                           => 'present',
  cluster                          => 'MyCluster01',
  node                             => 'appNode01',
  cell                             => 'CELL_01',
  jvm_maximum_heap_size            => '512',
  jvm_verbose_mode_class           => true,
  jvm_verbose_garbage_collection   => false,
  total_transaction_timeout        => '120',
  client_inactivity_timeout        => '20',
  threadpool_webcontainer_max_size => '75',
  runas_user                       => 'webadmin',
  runas_group                      => 'webadmins',
}
```

The DMGR declared a `websphere_application_server::cluster` defined type, which will automatically collect any exported resources that match its *cell*. Every time Puppet runs on the DMGR, it will search for exported resources to declare on that host.

On the application server, the "@@" prefixed to the resource type *exports* that resource, which can be collected by the DMGR the next time Puppet runs.

To explicitly add each member:

```puppet
websphere_application_server::cluster::member { 'AppServer01':
  ensure       => 'present',
  cluster      => 'MyCluster01',
  node         => 'appNode01',
  cell         => 'CELL_01',
  profile_base => '/opt/IBM/WebSphere/AppServer/profiles',
  dmgr_profile => 'PROFILE_DMGR_01',
}
```

### Configuring the instance

#### Variables

This module provides a type to manage WebSphere environment variables.

**Node-scoped variable:**

```puppet
websphere_variable { 'CELL_01:node:appNode01':
  ensure       => 'present',
  variable     => 'LOG_ROOT',
  value        => '/var/log/websphere/wasmgmtlogs/appNode01',
  scope        => 'node',
  node         => 'appNode01',
  cell         => 'CELL_01',
  dmgr_profile => 'PROFILE_APP_001',
  profile_base => '/opt/IBM/WebSphere/AppServer/profiles',
  user         => 'webadmin',
  require      => Websphere_application_server::Profile::Appserver['PROFILE_APP_001'],
}
```
In the example below, a variable called `LOG_ROOT` is set
for the *node* `appNode01`.

**Server scoped variable:**

```puppet
# NOTE: This will cause a FAILURE during the first Puppet run because the
# cluster member has not yet been created on the DMGR.
websphere_variable { 'CELL_01:server:appNode01:AppServer01':
  ensure       => 'present',
  variable     => 'LOG_ROOT',
  value        => '/opt/log/websphere/appserverlogs',
  scope        => 'server',
  server       => 'AppServer01',
  node         => 'appNode01',
  cell         => 'CELL_01',
  dmgr_profile => 'PROFILE_APP_001',
  profile_base => $profile_base,
  user         => $user,
  require      => Websphere_application_server::Profile::Appserver['PROFILE_APP_001'],
}
```

In the example above is a _server_ scoped variable for the
`AppServer01` server.  The `AppServer01` server was created as part of the
`websphere_application_server::cluster::member` defined type.

The server-scoped variables _cannot_ be managed until/unless
a corresponding cluster member exists on the DMGR. 

Optionally, these variables can be declared on the DMGR.  This allow
setting relationships between the cluster member and the variable resource.
However, this sacrifices some of the dynamic nature of the module.

#### JVM Logs

This module provides a `websphere_jvm_log` type that can be used to manage
JVM logging properties, such as log rotation criteria.

```puppet
websphere_jvm_log { "CELL_01:appNode01:node:AppServer01":
  profile             => 'PROFILE_APP_001',
  profile_base        => '/opt/IBM/WebSphere/AppServer/profiles',
  cell                => 'CELL_01',
  scope               => 'node',
  node                => 'appNode01',
  server              => 'AppServer01',
  out_filename        => '/tmp/SystemOut.log',
  out_rollover_type   => 'BOTH',
  out_rollover_size   => '7',
  out_maxnum          => '200',
  out_start_hour      => '13',
  out_rollover_period => '24',
  err_filename        => '/tmp/SystemErr.log',
  err_rollover_type   => 'BOTH',
  err_rollover_size   => '7',
  err_maxnum          => '3',
  err_start_hour      => '13',
  err_rollover_period => '24',
  require             => Websphere_application_server::Profile::Appserver['PROFILE_APP_001'],
}
```

In the example above, JVM logs are created for the `appNode01` node. Log
customizations include `filename`, `rollover_type`, `rollover_size`, `maxnum`,
`start_hour`, and `rollover_period` for both SystemOut and SystemErr logs.

#### JDBC Providers and Datasources

This module supports creating JDBC providers and data sources.  At this time,
it does not support the removal of JDBC providers or datasources or changing
their configuration after they're created.

**JDBC Provider:**

An example of creating a JDBC provider called "Puppet Test", using Oracle, at
node scope:

```puppet
websphere_jdbc_provider { 'Puppet Test':
  ensure         => 'present',
  dmgr_profile   => 'PROFILE_DMGR_01',
  profile_base   => '/opt/IBM/WebSphere/AppServer/profiles',
  user           => 'webadmin',
  scope          => 'node',
  cell           => 'CELL_01',
  node           => 'appNode01',
  server         => 'AppServer01',
  dbtype         => 'Oracle',
  providertype   => 'Oracle JDBC Driver',
  implementation => 'Connection pool data source',
  description    => 'Created by Puppet',
  classpath      => '${ORACLE_JDBC_DRIVER_PATH}/ojdbc6.jar',
}
```

**JDBC Datasource:**

An example of creating a datasource, utilizing the JDBC provider we created,
at node scope:

```puppet
websphere_jdbc_datasource { 'Puppet Test':
  ensure                        => 'present',
  dmgr_profile                  => 'PROFILE_DMGR_01',
  profile_base                  => '/opt/IBM/WebSphere/AppServer/profiles',
  user                          => 'webadmin',
  scope                         => 'node',
  cell                          => 'CELL_01',
  node                          => 'appNode01',
  server                        => 'AppServer01',
  jdbc_provider                 => 'Puppet Test',
  jndi_name                     => 'myTest',
  data_store_helper_class       => 'com.ibm.websphere.rsadapter.Oracle11gDataStoreHelper',
  container_managed_persistence => true,
  url                           => 'jdbc:oracle:thin:@//localhost:1521/sample',
  description                   => 'Created by Puppet',
}
```

**JDBC Provider at cell scope:**

```puppet
websphere_jdbc_provider { 'Puppet Test':
  ensure         => 'present',
  dmgr_profile   => 'PROFILE_DMGR_01',
  profile_base   => '/opt/IBM/WebSphere/AppServer/profiles',
  user           => 'webadmin',
  scope          => 'cell',
  cell           => 'CELL_01',
  dbtype         => 'Oracle',
  providertype   => 'Oracle JDBC Driver',
  implementation => 'Connection pool data source',
  description    => 'Created by Puppet',
  classpath      => '${ORACLE_JDBC_DRIVER_PATH}/ojdbc6.jar',
}
```

**JDBC Datasource at cell scope:**

```puppet
websphere_jdbc_datasource { 'Puppet Test':
  ensure                        => 'present',
  dmgr_profile                  => 'PROFILE_DMGR_01',
  profile_base                  => '/opt/IBM/WebSphere/AppServer/profiles',
  user                          => 'webadmin',
  scope                         => 'cell',
  cell                          => 'CELL_01',
  jdbc_provider                 => 'Puppet Test',
  jndi_name                     => 'myTest',
  data_store_helper_class       => 'com.ibm.websphere.rsadapter.Oracle11gDataStoreHelper',
  container_managed_persistence => true,
  url                           => 'jdbc:oracle:thin:@//localhost:1521/sample',
  description                   => 'Created by Puppet',
}
```

#### IHS

This module has basic support for managing IBM HTTP Server (IHS) in the context of WebSphere.

In the example below, creating an ihs instance will install IHS to `/opt/IBM/HTTPServer`, install the WebSphere plug-ins for IHS, and create a server instance.  By default, this module will automatically export a `websphere_node` and `websphere_web_server` resource via the `websphere_application_server::ihs::server` defined type. These exported resources will be collected by the DMGR and *realized*. By default, an IHS server will automatically be setup in the DMGR's cell.

```puppet
websphere_application_server::ihs::instance { 'HTTPServer':
  target           => '/opt/IBM/HTTPServer',
  package          => 'com.ibm.websphere.IHSILAN.v85',
  version          => '8.5.5000.20130514_1044',
  repository       => '/mnt/myorg/ihs/repository.config',
  install_options  => '-properties user.ihs.httpPort=80',
  user             => 'webadmin',
  group            => 'webadmins',
  manage_user      => false,
  manage_group     => false,
  log_dir          => '/opt/log/websphere/httpserver',
  admin_username   => 'httpadmin',
  admin_password   => 'password',
  webroot          => '/opt/web',
}

ibm_pkg { 'Plugins':
  ensure     => 'present',
  target     => '/opt/IBM/Plugins',
  repository => '/mnt/myorg/plugins/repository.config',
  package    => 'com.ibm.websphere.PLGILAN.v85',
  version    => '8.5.5000.20130514_1044',
  require    => Websphere_application_server::Ihs::Instance['HTTPServer'],
}

websphere_application_server::ihs::server { 'test':
  target      => '/opt/IBM/HTTPServer',
  log_dir     => '/opt/log/websphere/httpserver',
  plugin_dir  => '/opt/IBM/Plugins/config/test',
  plugin_base => '/opt/IBM/Plugins',
  cell        => 'CELL_01',
  config_file => '/opt/IBM/HTTPServer/conf/httpd_test.conf',
  access_log  => '/opt/log/websphere/httpserver/access_log',
  error_log   => '/opt/log/websphere/httpserver/error_log',
  listen_port => '10080',
  require     => Ibm_pkg['Plugins'],
}
```

### Accessing the DMGR Console

Once Websphere has completed install and DMGR is configured, the DMGR console can be accessed via a web browser at a URL similar to:

`http://<host>:9060/ibm/console/unsecureLogon.jsp`

## Reference

### Classes

#### Public Classes

* [`websphere_application_server`](#class-websphere_application_server)

### Defined Types

* [websphere_application_server::instance](#defined-type-websphere_application_serverinstance)
* [websphere_application_server::package](#defined-type-websphere_application_serverpackage)
* [websphere_application_server::ownership](#defined-type-websphere_application_serverownership)
* [websphere_application_server::profile::dmgr](#defined-type-websphere_application_serverprofiledmgr)
* [websphere_application_server::profile::appserver](#defined-type-websphere_application_serverprofileappserver)
* [websphere_application_server::profile::service](#defined-type-websphere_application_serverprofileservice)
* [websphere_application_server::ihs::instance](#defined-type-websphere_application_serverihsinstance)
* [websphere_application_server::ihs::server](#defined-type-websphere_application_serverihsserver)
* [websphere_application_server::cluster](#defined-type-websphere_application_servercluster)
* [websphere_application_server::cluster::member](#defined-type-websphere_application_serverclustermember)

### Types

* [websphere_app_server](#type-websphere_app_server)
* [websphere_cluster](#type-websphere_cluster)
* [websphere_cluster_member](#type-websphere_cluster_member)
* [websphere_cluster_member_service](#type-websphere_cluster_member_service)
* [websphere_federate](#type-websphere_federate)
* [websphere_jdbc_datasource](#type-websphere_jdbc_datasource)
* [websphere_jdbc_provider](#type-websphere_jdbc_provider)
* [websphere_jvm_log](#type-websphere_jvm_log)
* [websphere_node](#type-websphere_node)
* [websphere_sdk](#type-websphere_sdk)
* [websphere_variable](#type-websphere_variable)
* [websphere_web_server](#type-websphere_web_server)

### Facts

The following facts are provided by this module:

| Fact name                | Description                                      |
| ------------------------ | ------------------------------------------------ |
| *instance*\_name         | This is the name of a WebSphere instance. Basically, the base directory name.
| *instance*\_target       | The full path to where a particular instance is installed.
| *instance*\_user         | The user that "owns" this instance.
| *instance*\_group        | The group that "owns" this instance.
| *instance*\_profilebase  | The full path to where profiles for this instance are located.
| *instance*\_version      | The version of WebSphere an instance is running.
| *instance*\_package      | The package name a WebSphere instance was installed from.
| websphere\_profiles      | A comma-separated list of profiles discovered on a system across instances.
| websphere\_*profile*\_*cell*\_*node*\_soap | The SOAP port for an instance.  This is particuarily relevant on the DMGR so App servers can federate with it.

**Examples:**

Assuming we've installed a WebSphere instance called "WebSphere":

```
websphere_group => webadmins
websphere_name => WebSphere
websphere_package => com.ibm.websphere.NDTRIAL.v85
websphere_profile_base => /opt/IBM/WebSphere/AppServer/profiles
websphere_target => /opt/IBM/WebSphere/AppServer
websphere_user => webadmin
websphere_version => 8.5.5004.20141119_1746
websphere_base_dir => /optIBM
websphere_profile_dmgr_01_cell_01_appnode01_soap => 8878
websphere_profile_dmgr_01_cell_01_node_dmgr_01_soap => 8879
websphere_profiles => PROFILE_DMGR_01
```

Or if we've installed a WebSphere instance called "WebSphere85" to a custom
location:

```
websphere85_group => webadmins
websphere85_name => WebSphere85
websphere85_package => com.ibm.websphere.NDTRIAL.v85
websphere85_profile_base => /opt/myorg/IBM/WebSphere85/AppServer/profiles
websphere85_target => /opt/myorg/IBM/WebSphere85/AppServer
websphere85_user => webadmin
websphere85_version => 8.5.5004.20141119_1746
websphere_base_dir => /opt/myorg/IBM
websphere_profile_dmgr_01_cell_01_appnode01_soap => 8878
websphere_profile_dmgr_01_cell_01_node_dmgr_01_soap => 8879
websphere_profiles => PROFILE_DMGR_01
```
#### Class: `websphere_application_server`

The base class.

##### Parameters (all optional)

* `base_dir`: The base directory containing IBM Software. Valid options: an absolute path to a directory. Default: `/opt/IBM`.
* `group`: The permissions group for the WebSphere installation. Valid options: a string containing a valid group name. Default: `webadmins`.
* `manage_user`: Specifies whether the class will manage the user specified in `user`. Valid options: boolean. Default: true.
* `manage_group`: Specifies whether the class will manage the group specified in `group`. Valid options: boolean. Default: true.
* `user`: The user name that will own and execute the WebSphere installation. Valid options: a string containing a valid user name. Default: `webadmin`.
* `user_home`: Specifies the home directory for the specified user if `manage_user` is `true`. Valid options: an absolute path to a directory. Default: `/opt/IBM`.

**Note:** The following directories will be managed by the base class:

* `${base_dir}/.java`
* `${base_dir}/.java/systemPrefs`
* `${base_dir}/.java/userPrefs`
* `${base_dir}/workspace`
* `/opt/IBM/.java`
* `/opt/IBM/.java/systemPrefs`
* `/opt/IBM/.java/userPrefs`
* `/opt/IBM/workspace`

#### Defined Type: websphere_application_server::instance

Manages the base installation of a WebSphere instance.

**Parameters within `websphere_application_server::instance`**:

##### `base_dir`

Default is `$::websphere::base_dir`, as in, it will default to the value of `base_dir` that is specified when declaring the base class `websphere`.

This should point to the base directory that WebSphere instances should be installed to.  IBM's default is `/opt/IBM`

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

#### Defined Type: websphere_application_server::package

Manages the installation of IBM packages and the ownership of the installation directory.

**Parameters within `websphere_application_server::package`**:

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

#### Defined Type: websphere_application_server::ownership

Manages the ownership of a specified path. See notes below for the usecase for this.

**Parameters within `websphere_application_server::`**:

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

#### Defined Type: websphere_application_server::profile::dmgr

Manages a DMGR profile.

**Parameters within `websphere_application_server::`**:

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

#### Defined Type: websphere_application_server::profile::appserver

Manages an application server profile.

**Parameters within `websphere_application_server::`**:

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

#### Defined Type: websphere_application_server::profile::service

Manages the service for a profile (DMGR or Application Server).

**Parameters within `websphere_application_server::`**:

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

#### Defined Type: websphere_application_server::ihs::instance

Manages the installation of an IHS instance.

**Parameters within `websphere_application_server::`**:

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

#### Defined Type: websphere_application_server::ihs::server

Manages server instances on an IHS system.

**Parameters within `websphere_application_server::`**:

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

#### Defined Type: websphere_application_server::cluster

Manage WebSphere clusters.

**Parameters within `websphere_application_server::`**:

##### `ensure`

Specifies whether this cluster should exist or not.  Valid values are `present`
and `absent`.

Defaults to `present`

##### `profile_base`

Required. Specifies the full path to where WebSphere _profiles_ are stored.

The IBM default is `/opt/IBM/WebSphere/AppServer/profiles`

##### `dmgr_profile`

Required. The DMGR profile that this cluster should be created under. The
`wsadmin` tool is used from this profile.

Example: `PROFILE_DMGR_01`

##### `cell`

Required. The cell that this cluster should be created under.

##### `cluster`

The name of the cluster to manage.  Defaults to the resource title.

##### `collect_members`

Boolean. Defaults to `true`.

Specifies whether _exported_ resources relating to WebSphere clusters should
be _collected_ by this instance of the defined type.

If true, `websphere::cluster::member`, `websphere_cluster_member`, and
`websphere_cluster_member_service` resources will be _collected_ that match
this __cell__.

The use case for this is so application servers, for instance, can export
themselves as a cluster member in a certain cell.  When this defined type is
evaluated by a DMGR, those can automatically be collected.

##### `dmgr_host`

The resolvable hostname for the DMGR that this cluster exists on.  This is
needed for collecting cluster members.  Defaults to `$::fqdn`

##### `user`

The user that should run the `wsadmin` commands.  Defaults to
`$::websphere::user`

#### Defined Type: websphere_application_server::cluster::member

Manage WebSphere cluster members and their services.

**Parameters within `websphere_application_server::`**:

##### `ensure`

Valid values: `present`, `absent`

Defaults to `true`.  Specifies whether this cluster member should exist or not.

##### `cell`

Required. Specifies the cell that the cluster is under that this member should
be managed under.

##### `cluster_member_name`

Specifies the name for this cluster member.  Defaults to the resource title.

##### `cluster`

Required.  The name of the cluster that this member should be managed under.

##### `client_inactivity_timeout`

Optional.  Manages the clientInactivityTimeout for the TransactionService

##### `gen_unique_ports`

Optional. Boolean. Specifies the `genUniquePorts` value when adding a cluster
member.

Should be `true` or `false`

##### `jvm_maximum_heap_size`

Optional. Manages the `maximumHeapSize` setting for the cluster member's JVM

##### `jvm_verbose_mode_class`

Optional. Boolean. Manages the `verboseModeClass` setting for the cluster
member's JVM

##### `jvm_verbose_garbage_collection`

Optional. Boolean. Manages the `verboseModeGarbageCollection` setting for the
cluster member's JVM

##### `jvm_verbose_mode_jni`

Optional. Boolean. Manages the `verboseModeJNI` setting for the cluster
member's JVM

##### `jvm_initial_heap_size`

Optional. Manages the `initialHeapSize` setting for the cluster member's JVM

##### `jvm_run_hprof`

Optional. Boolean. Manages the `runHProf` setting for the cluster member's JVM

##### `jvm_hprof_arguments`

Optional. Manages the `hprofArguments` setting for the cluster member's JVM

##### `jvm_debug_mode`

Optional. Boolean. Manages the `debugMode` setting for the cluster member's JVM

##### `jvm_debug_args`

Optional. Manages the `debugArgs` setting for the cluster member's JVM

##### `jvm_executable_jar_filename`

Optional. Manages the `executableJarFileName` setting for the cluster member's
JVM

##### `jvm_generic_jvm_arguments`

Optional. Manages the `genericJvmArguments` setting for the cluster member's
JVM

##### `jvm_disable_jit`

Optional. Boolean. Manages the `disableJIT` setting for the cluster member's
JVM

##### `node`

The node that this cluster member should be created on.

##### `replicator_entry`

Not currently used.

##### `runas_group`

Optional. Manages the `runAsGroup` for a cluster member

##### `runas_user`

Optional. Manages the `runAsUser` for a cluster member

##### `total_transaction_timeout`

Optional. Manages the `totalTranLifetimeTimeout` for the Application Server

##### `threadpool_webcontainer_min_size`

Optional. Manages the `minimumSize` setting for the WebContainer ThreadPool

##### `threadpool_webcontainer_max_size`

Optional. Manages the `maximumSize` setting for the WebContainer ThreadPool

##### `umask`

Optional. Manages the `ProcessExecution` umask for a cluster member

##### `weight`

Optional. Manages the cluster member weight (`memberWeight`) when adding a
cluster member

##### `dmgr_profile`

Required. The name of the DMGR profile to create this cluster member under.

Examples: `PROFILE_DMGR_01` or `dmgrProfile01`

##### `profile_base`

Required. The full path to the profiles directory where the `dmgr_profile` can
be found.  The IBM default is `/opt/IBM/WebSphere/AppServer/profiles`

##### `user`

Optional. The user to run the `wsadmin` command as. Defaults to "root"

##### `dmgr_host`

The DMGR host to add this cluster member to.

This is required if you're exporting the cluster member for a DMGR to
collect.  Otherwise, it's optional.

##### `wsadmin_user`

Optional. The username for `wsadmin` authentication if security is enabled.

##### `wsadmin_pass`

Optional. The password for `wsadmin` authentication if security is enabled.

##### `manage_service`

Boolean. Defaults to `true`

Specifies whether the corresponding service for the cluster member should be
managed here or not.  This uses the `websphere_cluster_member_service` type
to do so.

#### Type: websphere_app_server

Manages WebSphere Application Servers

**Parameters within `websphere_application_server::`**:

##### `ensure`

Valid values: `present`, `absent`

Defaults to `true`.  Specifies whether this application server should exist or
not.

##### `name`

The name of the application server to create or manage.  Defaults to the
resource title.

##### `node`

Required. The name of the _node_ to create this server on.  Refer to the
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

#### Type: websphere_cluster

Manages the creation of WebSphere clusters on a DMGR.

**Parameters within `websphere_application_server::`**:

##### `ensure`

Valid values: `present`, `absent`

Defaults to `true`.  Specifies whether this cluster should exist or not.

##### `name`

The name of the cluster to manage. Defaults to the resource title.

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

#### Type: websphere_cluster_member

Manages cluster members, including various settings.

**Parameters within `websphere_application_server::`**:

##### `ensure`

Valid values: `present`, `absent`

Defaults to `true`.  Specifies whether this cluster member should exist or not.

##### `cell`

Required. Specifies the cell that the cluster is under that this member should
be managed under.

##### `cluster`

Required.  The name of the cluster that this member should be managed under.

##### `client_inactivity_timeout`

Optional.  Manages the clientInactivityTimeout for the TransactionService

##### `gen_unique_ports`

Optional. Boolean. Specifies the `genUniquePorts` value when adding a cluster
member.

Should be `true` or `false`

##### `jvm_maximum_heap_size`

Optional. Manages the `maximumHeapSize` setting for the cluster member's JVM

##### `jvm_verbose_mode_class`

Optional. Boolean. Manages the `verboseModeClass` setting for the cluster
member's JVM

##### `jvm_verbose_garbage_collection`

Optional. Boolean. Manages the `verboseModeGarbageCollection` setting for the
cluster member's JVM

##### `jvm_verbose_mode_jni`

Optional. Boolean. Manages the `verboseModeJNI` setting for the cluster
member's JVM

##### `jvm_initial_heap_size`

Optional. Manages the `initialHeapSize` setting for the cluster member's JVM

##### `jvm_run_hprof`

Optional. Boolean. Manages the `runHProf` setting for the cluster member's JVM

##### `jvm_hprof_arguments`

Optional. Manages the `hprofArguments` setting for the cluster member's JVM

##### `jvm_debug_mode`

Optional. Boolean. Manages the `debugMode` setting for the cluster member's JVM

##### `jvm_debug_args`

Optional. Manages the `debugArgs` setting for the cluster member's JVM

##### `jvm_executable_jar_filename`

Optional. Manages the `executableJarFileName` setting for the cluster member's
JVM

##### `jvm_generic_jvm_arguments`

Optional. Manages the `genericJvmArguments` setting for the cluster member's
JVM

##### `jvm_disable_jit`

Optional. Boolean. Manages the `disableJIT` setting for the cluster member's
JVM

##### `node`

##### `replicator_entry`

Not currently used.

##### `runas_group`

Optional. Manages the `runAsGroup` for a cluster member

##### `runas_user`

Optional. Manages the `runAsUser` for a cluster member

##### `total_transaction_timeout`

Optional. Manages the `totalTranLifetimeTimeout` for the Application Server

##### `threadpool_webcontainer_min_size`

Optional. Manages the `minimumSize` setting for the WebContainer ThreadPool

##### `threadpool_webcontainer_max_size`

Optional. Manages the `maximumSize` setting for the WebContainer ThreadPool

##### `umask`

Optional. Manages the `ProcessExecution` umask for a cluster member

##### `weight`

Optional. Manages the cluster member weight (`memberWeight`) when adding a
cluster member

##### `name`

The name of the server to add to the cluster. Defaults to the resource title.

##### `dmgr_profile`

Required. The name of the DMGR profile to create this cluster member under.

Examples: `PROFILE_DMGR_01` or `dmgrProfile01`

##### `profile_base`

Required. The full path to the profiles directory where the `dmgr_profile` can
be found.  The IBM default is `/opt/IBM/WebSphere/AppServer/profiles`

##### `dmgr_host`

The DMGR host to add this cluster member to.

This is required if you're exporting the cluster member for a DMGR to
collect.  Otherwise, it's optional.

##### `user`

Optional. The user to run the `wsadmin` command as. Defaults to "root"

##### `wsadmin_user`

Optional. The username for `wsadmin` authentication if security is enabled.

##### `wsadmin_pass`

Optional. The password for `wsadmin` authentication if security is enabled.

#### Type: websphere_cluster_member_service

Manages a cluster member service.

**Parameters within `websphere_application_server::`**:

##### `ensure`

Valid values: `running` or `stopped`

Defaults to `running`.  Specifies whether the service should be running or not.

##### `cell`

Required. The name of the cell that the cluster member belongs to.

##### `cluster`

Required. The cluster that the cluster member belongs to.

##### `name`

The name of the cluster member that this service belongs to.  Defaults to the
resource title.

##### `node`

Required. The name of the _node_ that this cluster member is on. Refer to the
`websphere_node` type for managing the creation of nodes.

##### `dmgr_profile`

Required. The name of the DMGR profile that this cluster member is running
under.

Examples: `PROFILE_DMGR_01` or `dmgrProfile01`

##### `profile_base`

Required. The full path to the profiles directory where the `dmgr_profile` can
be found.  The IBM default is `/opt/IBM/WebSphere/AppServer/profiles`

##### `user`

Optional. The user to run the `wsadmin` command as. Defaults to "root"

##### `dmgr_host`

The DMGR host to add this cluster member to.

This is required if you're exporting the cluster member for a DMGR to
collect.  Otherwise, it's optional.

##### `wsadmin_user`

Optional. The username for `wsadmin` authentication if security is enabled.

##### `wsadmin_pass`

Optional. The password for `wsadmin` authentication if security is enabled.

#### Type: websphere_federate

Manages the federation of an application server with a cell.

**Parameters within `websphere_application_server::`**:

##### `ensure`

Valid values: `present`, `absent`

Defaults to `present`.  Specifies whether this application server profile
should be federated or not.  Executes `addNode.sh` or `removeNode.sh` under the
hood.

##### `cell`

Required. The name of the cell to federate with.

##### `node`

Required. The name of the _node_ to federate.

##### `profile`

Required. The name of the _profile_ to federate.

##### `profile_base`

Required. The full path to the profiles directory where the `profile` can
be found.  The IBM default is `/opt/IBM/WebSphere/AppServer/profiles`

##### `soap_port`

The DMGR SOAP port to connect to for federation.  This is only needed if a
data file has *not* been exported from the DMGR and if you're declaring this
resource manually.

##### `options`

Any custom options to pass to the `addNode.sh` or `removeNode.sh` commands
for federation or de-federation.

##### `user`

Optional. The user to run the `addNode.sh` or `removeNode.sh` command as.
Defaults to "root"

##### `username`

Optional. The username for `addNode.sh` authentication if security is enabled.

##### `password`

Optional. The password for `addNode.sh` authentication if security is enabled.

#### Type: websphere_jdbc_datasource

Manages datasources.

**Parameters within `websphere_application_server::`**:

##### `ensure`

Valid values: `present`, `absent`

Defaults to `present`.  Specifies whether this datasource should exist or not.

##### `scope`

Required. The _scope_ to manage this JDBC datasource at.

Valid values are: node, server, cell, or cluster.

##### `cell`

Required.  The cell that this datasource should be managed under.

##### `node`

Required if `scope` is server or node.

##### `server`

Required if `scope` is server.

##### `cluster`

Required if `scope` is cluster.

##### `dmgr_profile`

Required. The name of the DMGR _profile_ that this datasource should be
managed under.

##### `profile_base`

Required. The full path to the profiles directory where the `dmgr_profile` can
be found.  The IBM default is `/opt/IBM/WebSphere/AppServer/profiles`

##### `name`

The name of the datasource.  Defaults to the resource title.

##### `jdbc_provider`

Required. The name of the JDBC provider to use for this datasource.

##### `jndi_name`

Required. The JNDI name. This corresponds to the `wsadmin` argument `-jndiName`

Example: `jndc/foo`

##### `data_store_helper_class`

Required.  Corresponds to the `wsadmin` argument `-dataStoreHelperClassName`

Examples: `com.ibm.websphere.rsadapter.Oracle11gDataStoreHelper` or
`com.ibm.websphere.rsadapter.Oracle11gDataStoreHelper`

##### `container_managed_persistence`

AKA "CMP"

Boolean.

Corresponds to the `wsadmin` argument `-componentManagedAuthenticationAlias`

##### `url`

Required for Oracle providers.

The JDBC URL.

Only relevant when the `data_store_helper_class` is
`com.ibm.websphere.rsadapter.Oracle11gDataStoreHelper`

Example: `jdbc:oracle:thin:@//localhost:1521/sample`

##### `description`

An optional description for the datasource.

##### `db2_driver`

The driver for DB2 datasources.  Only relevant when that's the provider.

This only applies when the `data_store_helper_class` is
`com.ibm.websphere.rsadapter.DB2UniversalDataStoreHelper`

##### `database`

The database name for DB2 and Microsoft SQL Server.

This is only relevant when the `data_store_helper_class` is one of:

* `com.ibm.websphere.rsadapter.DB2UniversalDataStoreHelper`
* `com.ibm.websphere.rsadapter.MicrosoftSQLServerDataStoreHelper`

##### `db_server`

The database server address.

This is only relevant when the `data_store_helper_class` is one of:

* `com.ibm.websphere.rsadapter.DB2UniversalDataStoreHelper`
* `com.ibm.websphere.rsadapter.MicrosoftSQLServerDataStoreHelper`

##### `db_port`

The database server port.

This is only relevant when the `data_store_helper_class` is one of:


* `com.ibm.websphere.rsadapter.DB2UniversalDataStoreHelper`
* `com.ibm.websphere.rsadapter.MicrosoftSQLServerDataStoreHelper`

##### `db_port`

The database server port.

This is only relevant when the `data_store_helper_class` is one of:

* `com.ibm.websphere.rsadapter.DB2UniversalDataStoreHelper`
* `com.ibm.websphere.rsadapter.MicrosoftSQLServerDataStoreHelper`

##### `component_managed_auth_alias`

Corresponds to the `wsadmin` argument `-componentManagedAuthenticationAlias`

##### `user`

Optional. The user to run the `wsadmin` command as. Defaults to "root"

##### `wsadmin_user`

Optional. The username for `wsadmin` authentication if security is enabled.

##### `wsadmin_pass`

Optional. The password for `wsadmin` authentication if security is enabled.

#### Type: websphere_jdbc_provider

Manages JDBC providers.

**Parameters within `websphere_application_server::`**:

##### `ensure`

Valid values: `present`, `absent`

Defaults to `present`.  Specifies whether this provider should exist or not.

##### `scope`

Required. The _scope_ to manage this JDBC provider at.

Valid values are: node, server, cell, or cluster.

##### `cell`

Required.  The cell that this provider should be managed under.

##### `node`

Required if `scope` is server or node.

##### `server`

Required if `scope` is server.

##### `cluster`

Required if `scope` is cluster.

##### `dbtype`

The type of database for the JDBC Provider.
This corresponds to the wsadmin argument `-databaseType`
Examples: DB2, Oracle

Consult IBM's documentation for the types of valid databases.

##### `providertype`

The provider type for this JDBC Provider.
This corresponds to the wsadmin argument `-providerType`

Examples:

* "Oracle JDBC Driver"
* "DB2 Universal JDBC Driver Provider"
* "DB2 Using IBM JCC Driver"

Consult IBM's documentation for valid provider types.

##### `implementation`

The implementation type for this JDBC Provider.
This corresponds to the wsadmin argument `-implementationType`

Example: "Connection pool data source"

Consult IBM's documentation for valid implementation types.

##### `classpath`

The classpath for this provider.
This corresponds to the wsadmin argument `-classpath`

Examples:

* `${ORACLE_JDBC_DRIVER_PATH}/ojdbc6.jar`
* `${DB2_JCC_DRIVER_PATH}/db2jcc4.jar ${UNIVERSAL_JDBC_DRIVER_PATH}/db2jcc_license_cu.jar`

Consult IBM's documentation for valid classpaths.

##### `nativepath`

The nativepath for this provider.
This corresponds to the wsadmin argument `-nativePath`

This can be blank.

Examples: `${DB2UNIVERSAL_JDBC_DRIVER_NATIVEPATH}`

Consult IBM's documentation for valid native paths.

##### `dmgr_profile`

Required. The name of the DMGR _profile_ that this provider should be
managed under.

##### `profile_base`

Required. The full path to the profiles directory where the `dmgr_profile` can
be found.  The IBM default is `/opt/IBM/WebSphere/AppServer/profiles`

##### `name`

The name of the provider. Defaults to the resource title.

##### `description`

An optional description for the provider.

##### `user`

Optional. The user to run the `wsadmin` command as. Defaults to "root"

##### `wsadmin_user`

Optional. The username for `wsadmin` authentication if security is enabled.

##### `wsadmin_pass`

Optional. The password for `wsadmin` authentication if security is enabled.

#### Type: websphere_jvm_log

Manages the JVM logging properties for nodes or servers.

**Parameters within `websphere_application_server::`**:

##### `scope`

Required. The scope to manage the properties at.

Valid values are 'node' and 'server'

##### `server`

The server to manage the properties on. Required if `scope` is 'server'

##### `cell`

Required. The cell that the node or server belongs to

##### `node`

Required.  The node to manage properties on.

##### `out_filename`

The file `System`.out filename. Can include WebSphere variables

##### `err_filename`

The file `System`.err filename. Can include WebSphere variables

##### `out_rollover_type`

Type of log rotation to enable for "SystemOut"

Valid values are: `SIZE`, `TIME`, or `BOTH`

##### `err_rollover_type`

Type of log rotation to enable for "SystemErr"

Valid values are: `SIZE`, `TIME`, or `BOTH`

##### `out_rollover_size`

Filesize in MB for log rotation of SystemOut.

##### `err_rollover_size`

Filesize in MB for log rotation of SystemErr.

##### `out_maxnum`

Maximum number of historical log files for SystemOut. 1-200.

##### `err_maxnum`

Maximum number of historical log files for SystemErr. 1-200.

##### `out_start_hour`

Start time for time-based log rotation of SystemOut. 1-24.

##### `err_start_hour`

Start time for time-based log rotation of SystemErr. 1-24.

##### `out_rollover_period`

Time period (log repeat time) for time-based log rotation of SystemOut. 1-24.

##### `err_rollover_period`

Time period (log repeat time) for time-based log rotation of SystemErr. 1-24.

##### `profile`
##### `name`


##### `name`

The name of the application server to create or manage.  Defaults to the
resource title.

##### `node`

Required. The name of the _node_ to create this server on.  Refer to the
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

#### Type: websphere_node

Manages the creation of unmanaged nodes in a WebSphere cell.

**Parameters within `websphere_application_server::`**:

##### `ensure`

Valid values: `present`, `absent`

Defaults to `true`.  Specifies whether this node should exist or not.

##### `name`

The name of the node to add. Defaults to the resource's title.

##### `hostname`

The hostname that the server can be reached at - probably the FQDN.

##### `node`

The name of the node manage.  Synonomous with `name`.  Defaults to the value
of `name`.  I'm not sure why both exist - name is actually only used to
identify the Puppet resource, but the `node` parameter value is what gets
translated into `wsadmin` arguments.

##### `os`

Required. The Operating System of the node you're adding.

Valid values are: `linux` and `aix`

Defaults to `linux`

##### `cell`

The cell that this node should belong to.  This has no influence over the
`wsadmin` command, but is used for instances where exported/collected
resources are used.  For example, if an IHS server _exports_ a `websphere_node`
resource and a DMGR collects it, it should collect based on the cell it's
managing.

##### `dmgr_profile`

Required. The name of the DMGR profile to create this node under.

Examples: `PROFILE_DMGR_01` or `dmgrProfile01`

##### `profile_base`

Required. The full path to the profiles directory where the `dmgr_profile` can
be found.  The IBM default is `/opt/IBM/WebSphere/AppServer/profiles`

##### `dmgr_host`

The DMGR host to add this node to.

This is required if you're exporting the node for a DMGR to
collect.  Otherwise, it's optional.

##### `user`

Optional. The user to run the `wsadmin` command as. Defaults to "root"

##### `wsadmin_user`

Optional. The username for `wsadmin` authentication if security is enabled.

##### `wsadmin_pass`

Optional. The password for `wsadmin` authentication if security is enabled.

#### Type: websphere_sdk

Manages the SDK version for a WebSphere profile or server.

**Parameters within `websphere_application_server::`**:

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

#### Type: websphere_variable

Manages WebSphere environment variables.

**Parameters within `websphere_application_server::`**:

##### `ensure`

Valid values: `present`, `absent`

Defaults to `true`.  Specifies whether this variable should exist or not.

##### `variable`

Required. The name of the variable to create/modify/remove.  For example,
`LOG_ROOT`

##### `value`

Required. The value that the specified variable should be set to.

##### `description`

Optional. A human-readable description for the variable.

Defaults to "Managed by Puppet"

##### `scope`

Required. The scope for the variable.

Valid values are: `cell`, `cluster`, `node`, or `server`

##### `server`

The server in the scope for this variable.

Required when `scope` is `server`

##### `cell`

Required. The cell that this variable should be set in.

##### `node`

The node that this variable should be set under.  This is required when scope
is set to `node` or `server`

##### `cluster`

The cluster that a variable should be set in.  This is required when scope is
set to `cluster`

##### `profile`

The profile that can be used to run the `wsadmin` command from.

Example: `dmgrProfile01` or `PROFILE_APP_01`

##### `dmgr_profile`

Synonomous with the `profile` parameter.

The DMGR profile that this variable should be set under.  The `wsadmin` tool
will be found here.

Example: `dmgrProfile01` or `PROFILE_DMGR_001`

##### `name`

The name of the resource. This is only used for Puppet to identify
the resource and has no influence over the commands used to make
modifications or query WebSphere variables.

##### `profile_base`

Required. The full path to the profiles directory where the `profile` can
be found.  The IBM default is `/opt/IBM/WebSphere/AppServer/profiles`

##### `user`

Optional. The user to run the `wsadmin` command as. Defaults to "root"

##### `wsadmin_user`

Optional. The username for `wsadmin` authentication if security is enabled.

##### `wsadmin_pass`

Optional. The password for `wsadmin` authentication if security is enabled.

#### Type: websphere_web_server

Manages the creation and configuration of WebSphere web servers.

**Parameters within `websphere_application_server::`**:

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

## Limitations

Tested and developed with **IBM WebSphere Application Server Network Deployment**.

Tested and developed with IBM WebSphere **8.5.0.x** and **8.5.5.x** on:

* CentOS 6 x86_64
* RHEL 6 x86_64

## Dependencies

* [puppetlabs/ibm_installation_manager](https://github.com/puppetlabs/puppetlabs-ibm_installation_manager)
* [puppetlabs/stdlib](https://forge.puppetlabs.com/puppetlabs/stdlib)
* [puppetlabs/concat](https://forge.puppetlabs.com/puppetlabs/concat)

## Development and Contributing

### TODO

There's plenty to do here.  WebSphere is a large software stack and this module only manages some core functions.  See [CONTRIBUTING.md](CONTRIBUTING.md) for information on contributing.

Some of the immediate needs:

* Revise types/providers.  Clean up the code, add validation and documentation.
    * `websphere_cluster_member` doesn't manage the individual properties on
      the first run.  The first run creates the member and subsequent runs
      configure it.  Need to resolve this - it's a provider issue.
* Manage WAS security.
* Manage certificates.
* Improve the run order issues.  See the [ISSUES.md](issues.md) file for
  details.
* Documentation and examples.
* Vagrant environment (I have one, just need to clean it up)

### Contributors

* Josh Beard <beard@puppetlabs.com>
* Gabe Schuyler <gabe@puppetlabs.com>
* Jonathan Hooker
* For more, see the [list of contributors.](https://github.com/puppetlabs/puppetlabs-websphere_application_server/graphs/contributors)
