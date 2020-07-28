# Change log

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org).

## [v2.1.0](https://github.com/puppetlabs/puppetlabs-websphere_application_server/tree/v2.1.0) (2020-07-28)

[Full Changelog](https://github.com/puppetlabs/puppetlabs-websphere_application_server/compare/v2.0.1...v2.1.0)

### Added

- Add resources, improve existing resources [\#201](https://github.com/puppetlabs/puppetlabs-websphere_application_server/pull/201) ([bFekete](https://github.com/bFekete))
- \(IAC-746\) - Add ubuntu 20.04 support [\#200](https://github.com/puppetlabs/puppetlabs-websphere_application_server/pull/200) ([david22swan](https://github.com/david22swan))
- A Puppet Plan which can be used to clone an IBM WAS Package/FixPack repository [\#188](https://github.com/puppetlabs/puppetlabs-websphere_application_server/pull/188) ([psreed](https://github.com/psreed))

## [v2.0.1](https://github.com/puppetlabs/puppetlabs-websphere_application_server/tree/v2.0.1) (2020-01-21)

[Full Changelog](https://github.com/puppetlabs/puppetlabs-websphere_application_server/compare/v2.0.0...v2.0.1)

### Fixed

- Ensure jdbc classpath param is properly quoted [\#190](https://github.com/puppetlabs/puppetlabs-websphere_application_server/pull/190) ([sheenaajay](https://github.com/sheenaajay))

## [v2.0.0](https://github.com/puppetlabs/puppetlabs-websphere_application_server/tree/v2.0.0) (2019-05-20)

[Full Changelog](https://github.com/puppetlabs/puppetlabs-websphere_application_server/compare/1.4.2...v2.0.0)

### Changed

- pdksync - \(MODULES-8444\) - Raise lower Puppet bound [\#165](https://github.com/puppetlabs/puppetlabs-websphere_application_server/pull/165) ([david22swan](https://github.com/david22swan))

### Fixed

- Modules 7472 - Websphere\_application\_server: Instance installation fails with nil conversion [\#162](https://github.com/puppetlabs/puppetlabs-websphere_application_server/pull/162) ([lionce](https://github.com/lionce))

## [1.4.2](https://github.com/puppetlabs/puppetlabs-websphere_application_server/tree/1.4.2) (2019-02-12)

[Full Changelog](https://github.com/puppetlabs/puppetlabs-websphere_application_server/compare/1.4.1...1.4.2)

## [1.4.1](https://github.com/puppetlabs/puppetlabs-websphere_application_server/tree/1.4.1) (2019-01-30)

[Full Changelog](https://github.com/puppetlabs/puppetlabs-websphere_application_server/compare/1.4.0...1.4.1)

### Fixed

- \(MODULES-7815\) - Fix issues with WebSphere 9 cluster membership [\#147](https://github.com/puppetlabs/puppetlabs-websphere_application_server/pull/147) ([eimlav](https://github.com/eimlav))
- pdksync - \(FM-7655\) Fix rubygems-update for ruby \< 2.3 [\#142](https://github.com/puppetlabs/puppetlabs-websphere_application_server/pull/142) ([tphoney](https://github.com/tphoney))

## [1.4.0](https://github.com/puppetlabs/puppetlabs-websphere_application_server/tree/1.4.0) (2018-09-27)

[Full Changelog](https://github.com/puppetlabs/puppetlabs-websphere_application_server/compare/1.3.0...1.4.0)

### Added

- pdksync - \(FM-7392\) - Puppet 6 Testing Changes [\#133](https://github.com/puppetlabs/puppetlabs-websphere_application_server/pull/133) ([pmcmaw](https://github.com/pmcmaw))
- pdksync - \(MODULES-6805\) metadata.json shows support for puppet 6 [\#132](https://github.com/puppetlabs/puppetlabs-websphere_application_server/pull/132) ([tphoney](https://github.com/tphoney))
- \(FM-7257\) - Addition of support for Ubuntu 18.04 [\#123](https://github.com/puppetlabs/puppetlabs-websphere_application_server/pull/123) ([david22swan](https://github.com/david22swan))

## 1.3.0
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


\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*
