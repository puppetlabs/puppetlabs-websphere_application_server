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

* [websphere_application_server::instance](docs/defines/instance.md)
* [websphere_application_server::package](docs/defines/package.md)
* [websphere_application_server::ownership](docs/defines/ownership.md)
* [websphere_application_server::profile::dmgr](docs/defines/profile_dmgr.md)
* [websphere_application_server::profile::appserver](docs/defines/profile_app.md)
* [websphere_application_server::profile::service](docs/defines/profile_service.md)
* [websphere_application_server::ihs::instance](docs/defines/ihs_instance.md)
* [websphere_application_server::ihs::server](docs/defines/ihs_server.md)
* [websphere_application_server::cluster](docs/defines/cluster.md)
* [websphere_application_server::cluster::member](docs/defines/cluster_member.md)

### Types

* [websphere_app_server](docs/types/websphere_app_server.md)
* [websphere_cluster](docs/types/websphere_cluster.md)
* [websphere_cluster_member](docs/types/websphere_cluster_member.md)
* [websphere_cluster_member_service](docs/types/websphere_cluster_member_service.md)
* [websphere_federate](docs/types/websphere_federate.md)
* [websphere_jdbc_datasource](docs/types/websphere_jdbc_datasource.md)
* [websphere_jdbc_provider](docs/types/websphere_jdbc_provider.md)
* [websphere_jvm_log](docs/types/websphere_jvm_log.md)
* [websphere_node](docs/types/websphere_node.md)
* [websphere_sdk](docs/types/websphere_sdk.md)
* [websphere_variable](docs/types/websphere_variable.md)
* [websphere_web_server](docs/types/websphere_web_server.md)

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

#### Defined Type: websphere_application_server::package

Manages the installation of IBM packages and the ownership of the installation directory.

#### Defined Type: websphere_application_server::ownership

Manages the ownership of a specified path. See notes below for the usecase for this.

#### Defined Type: websphere_application_server::profile::dmgr

Manages a DMGR profile.

#### Defined Type: websphere_application_server::profile::appserver

Manages an application server profile.

#### Defined Type: websphere_application_server::profile::service

Manages the service for a profile (DMGR or Application Server).

#### Defined Type: websphere_application_server::ihs::instance

Manages the installation of an IHS instance.

#### Defined Type: websphere_application_server::ihs::server

Manages server instances on an IHS system.

#### Defined Type: websphere_application_server::cluster

Manage WebSphere clusters.

#### Defined Type: websphere_application_server::cluster::member

Manage WebSphere cluster members and their services.

#### Type: websphere_app_server

Manages WebSphere Application Servers

#### Type: websphere_cluster

Manages the creation of WebSphere clusters on a DMGR.

#### Type: websphere_cluster_member

Manages cluster members, including various settings.

#### Type: websphere_cluster_member_service

Manages a cluster member service.

#### Type: websphere_federate

Manages the federation of an application server with a cell.

#### Type: websphere_jdbc_datasource

Manages datasources.

#### Type: websphere_jdbc_provider

Manages JDBC providers.

#### Type: websphere_jvm_log

Manages the JVM logging properties for nodes or servers.

#### Type: websphere_node

Manages the creation of unmanaged nodes in a WebSphere cell.

#### Type: websphere_sdk

Manages the SDK version for a WebSphere profile or server.

#### Type: websphere_variable

Manages WebSphere environment variables.

#### Type: websphere_web_server

Manages the creation and configuration of WebSphere web servers.


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
