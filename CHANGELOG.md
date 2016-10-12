## Supported Release 1.0.0
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


## Release 0.2.0
### Summary
This is the initial release of websphere_application_server on the forge. This module has the capability to install and configure websphere application servers, deployment managers, and websphere ihs via the IBM Installation Manager. This module does not support Liberty profiles.
