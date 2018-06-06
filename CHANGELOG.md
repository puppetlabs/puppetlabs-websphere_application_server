# Change log
All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org).

## Supported Release [1.3.0]
### Summary
This is a feature release enabling the installation of WebSphere AppServer 9.

#### Added
- `$jdk_package_name` and `$jdk_package_version` parameters for the `websphere_application_server::instance` type. Using these parameters requires puppetlabs-ibm_installation_manager >= 0.5.0. ([MODULES-4738](https://tickets.puppet.com/browse/MODULES-4738))

## Supported Release [1.2.0]
### Summary
This is a 'minor' feature release, that implements a variety of changes across websphere to ensure that it complies with the set rubocop rules and that it works with the pdk tool.

#### Added
- Code has been changed to work with the PDK tool. ([MODULES-6461](https://tickets.puppetlabs.com/browse/MODULES-6461))

#### Fixed
- Code has been updated to comply with the set Rubocop rules. ([MODULES-6518](https://tickets.puppetlabs.com/browse/MODULES-6518))

## Supported Release [1.1.0]
### Summary
This is a 'small' feature release, allowing the user to install WAS as a non-root user

#### Added
- passing of $user to `ibm_pkg` resource in `websphere_application_server::instance` ([MODULES-4903](https://tickets.puppetlabs.com/browse/MODULES-4903))

## Supported Release [1.0.1]
### Summary
This is a bugfix release that also features several modulesync updates.

#### Fixed
- `cell` parameter for jdbc resources is now validated by Puppet (FM-6126)
- Find wsadmin script in profile with backup (FM-5980)
- IHS exported resources (FM-5946)
- Adds check in get_xml_val to verify that server_xml exists (FM-6002)

## Supported Release [1.0.0]
### Summary
This is the first supported release of websphere_application_server on the forge. This release features support for Ubuntu, in addition to many bugfixes and a full acceptance test suite.

### Features
- Adds support for Ubuntu 14.04 and 16.04.
- Adds service management to IHS Server.

### Bugfixes
- Fixes pluginsync autoload problems
- Fixes `sync_nodes` failure on federation
- (FM-5418) Fix jython command options for jdbc_datasource provider
- Fixes all `exec` calls to be idempotent
- Fixes a permissions issue when running on RHEL7
- Adjusts acceptable return codes from wsadmin scripts.
- Fixes an error due to incorrect path to puppet bin directory.
- Fixes a bug when trying to retrieve xml values on appservers

### Backwards Incompatibility
- The `node` parameter in all defined and custom types have been renamed to `node_name` to workaround an issue with puppet-lint.


## Release [0.2.0]
### Summary
This is the initial release of websphere_application_server on the forge. This module has the capability to install and configure websphere application servers, deployment managers, and websphere ihs via the IBM Installation Manager. This module does not support Liberty profiles.


[1.3.0]:https://github.com/puppetlabs/puppetlabs-websphere_application_server/compare/1.2.0...1.3.0
[1.2.0]:https://github.com/puppetlabs/puppetlabs-websphere_application_server/compare/1.1.0...1.2.0
[1.1.0]:https://github.com/puppetlabs/puppetlabs-websphere_application_server/compare/1.0.1...1.1.0
[1.0.1]:https://github.com/puppetlabs/puppetlabs-websphere_application_server/compare/1.0.0...1.0.1
[1.0.0]:https://github.com/puppetlabs/puppetlabs-websphere_application_server/compare/0.2.0...1.0.0
[0.2.0]:https://github.com/puppetlabs/puppetlabs-websphere_application_server/compare/829cca4209d870355980f7cba40c9ce1db2c4573...0.2.0
