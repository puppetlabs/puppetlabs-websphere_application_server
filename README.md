# IBM WebSphere

#### Table of Contents

1. [Overview](#overview)
2. [TODO](#todo)
3. [Reference](#reference)
    * [Facts](#facts)
    * [Classes](#classes)
    * [Defined Types](#defined-types)
    * [Types](#types)
4. [Usage](#usage)
    * [Examples](#examples)
5. [Limitations](#limitations)
6. [Dependencies](#dependencies)
7. [Authors](#authors)
8. [Contributors](#contributors)

## Overview

Manages the deployment and configuration of IBM WebSphere Cells.

* DMGR systems and configuration
* Application Servers and configuration
* IHS Servers in the context of WebSphere

## TODO

There's plenty to do here.  WebSphere is a _huge_ stack and this module only
manages some core functions.  See [CONTRIBUTING.md](CONTRIBUTING.md) for
information on contributing.

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

## Reference

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

### Classes

Only one class currently exists in this class - the base class. Since this
module was designed for "multiple instances of anything", most things are
_defined types_.

| Class Name | Description                                                    |
| ---------- | -------------------------------------------------------------- |
| websphere  | Base class. Manages a user and group, a couple of data directories for WebSphere, and a YAML fact that includes metadata about WebSphere installations.

The following directories will be managed by the base class:

* `${base_dir}/.java`
* `${base_dir}/.java/systemPrefs`
* `${base_dir}/.java/userPrefs`
* `${base_dir}/workspace`
* `/opt/IBM/.java`
* `/opt/IBM/.java/systemPrefs`
* `/opt/IBM/.java/userPrefs`
* `/opt/IBM/workspace`

These directories appear to be necessary for the proper functionality of the
various IBM tools we use to manage the WebSphere deployment.

### Defined Types

The following defined types are provided by this module.

Each defined type is documented in a separate document in the
[docs/defines](docs/defines) directory.

| Defined Type Name             | Description                                 |
| ----------------------------- | ------------------------------------------- |
| [websphere::instance](docs/defines/instance.md) | Manages the base installation of a WebSphere instance.
| [websphere::package](docs/defines/package.md) | Manages the installation of IBM packages and the ownership of the installation directory.
| [websphere::ownership](docs/defines/ownership.md) | Manages the ownership of a specified path. See notes below for the usecase for this.
| [websphere::profile::dmgr](docs/defines/profile_dmgr.md) | Manages a DMGR profile.
| [websphere::profile::appserver](docs/defines/profile_app.md) | Manages an application server profile.
| [websphere::profile::service](docs/defines/profile_service.md) | Manages the service for a profile (DMGR or Application Server).
| [websphere::ihs::instance](docs/defines/ihs_instance.md) | Manages the installation of an IHS instance.
| [websphere::ihs::server](docs/defines/ihs_server.md) | Manages server instances on an IHS system.
| [websphere::cluster](docs/defines/cluster.md) | Manage WebSphere clusters.
| [websphere::cluster::member](docs/defines/cluster_member.md) | Manage WebSphere cluster members and their services.

### Types

The following native (Ruby) types are provided by this module.

Each type is documented in a separate document in the [docs/types](docs/types)
directory.

| Type                             | Description
| -------------------------------- | ---------------------------------------------------------------- |
| [websphere_app_server](docs/types/websphere_app_server.md) | Manages WebSphere Application Servers
| [websphere_cluster](docs/types/websphere_cluster.md) | Manages the creation of WebSphere clusters on a DMGR.
| [websphere_cluster_member](docs/types/websphere_cluster_member.md) | Manages cluster members, including various settings.
| [websphere_cluster_member_service](docs/types/websphere_cluster_member_service.md) | Manages a cluster member service.
| [websphere_federate](docs/types/websphere_federate.md) | Manages the federation of an application server with a cell.
| [websphere_jdbc_datasource](docs/types/websphere_jdbc_datasource.md) | Manages datasources.
| [websphere_jdbc_provider](docs/types/websphere_jdbc_provider.md) | Manages JDBC providers.
| [websphere_jvm_log](docs/types/websphere_jvm_log.md) | Manages the JVM logging properties for nodes or servers.
| [websphere_node](docs/types/websphere_node.md) | Manages the creation of unmanaged nodes in a WebSphere cell.
| [websphere_sdk](docs/types/websphere_sdk.md) | Manages the SDK version for a WebSphere profile or server.
| [websphere_variable](docs/types/websphere_variable.md) | Manages WebSphere environment variables.
| [websphere_web_server](docs/types/websphere_web_server.md) | Manages the creation and configuration of WebSphere web servers.

## Usage

### Examples

TODO.

See the [examples](examples/) directory for now.

Once it's up, you should be able to reach the DMGR console at something like:

`http://<host>:9060/ibm/console/unsecureLogon.jsp`

## Limitations

Tested with IBM WebSphere 8.5 on CentOS 6 x86_64.

Tested and developed with IBM WebSphere Application Server Network Deployment.

## Dependencies

* [joshbeard/ibm_installation_manager](https://github.com/joshbeard/puppet-ibm_installation_manager)
* [puppetlabs/stdlib](https://forge.puppetlabs.com/puppetlabs/stdlib)
* [puppetlabs/concat](https://forge.puppetlabs.com/puppetlabs/concat)

## Authors

Copyright 2015 Puppet Labs, Inc.

Josh Beard <beard@puppetlabs.com>

## Contributors

* Gabe Schuyler <gabe@puppetlabs.com>
* Jonathan Hooker
