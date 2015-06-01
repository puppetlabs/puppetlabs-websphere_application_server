# Issues

## Run Order

Due to the nature of exported resources and facter, we have some tricky
scenarios to reach convergence across a WebSphere cell.

Basically, to ensure success, things need to be ran in this order:

1. DMGR
2. Additional DMGR run
2. App servers
3. DMGR again to collect any cluster members

If things are not ran in this order, there will be errors during catalog
application.  These errors are recoverable, however.  Eventually, convergence
will be reached without human intervention. Refer to the points below for
reasons why this happens.

This is really only significant in situations where a brand new _cell_ is
being deployed (as in, a new DMGR).  Adding Application servers to a cell
that's already available isn't so picky.

### Overview:

#### DMGR first run:

* Fact for soap port is available, but not populated.
* Profile gets created, providing a soap port.
* Exporting the soap port isn’t possible yet because the fact has already been
evaluated.

#### DMGR second run:
* Fact for soap port is now able to query the data
* The soap port export is now possible, because facter was able to read the
soap port

#### App node first run:

* Federation will be attempted.  This requires the soap port to have been
  collected from the DMGR.
* A `cluster_member` resource and `cluster_member_service` resource gets
  exported for the DMGR to collect.
* Certain WebSphere variables (e.g. `LOG_ROOT`) will attempt to be modified.
  Some of these may require that the cluster service is running. This will
  fail until the cluster member is created and its service is running _on the
  DMGR_.

#### Additional DMGR runs:

* Any exported “`cluster_member`” and “`cluster_member_service`” resources will
  be collected and realized.
* This actually always happens, but there are no exported resources until an
  app server has ran at least once to export themselves.
* Cluster member properties will get configured.  This, happens during a Puppet
  run _after_ a run that created the cluster member.  This can be resolved in
  the code for the `cluster_member` provider.

### Overall observations

* We cannot make relationships on exported resources on
the agent that’s exporting it.  The relationships are part of the export - they
aren’t _realized_ by the agent doing the export.  So the app server exports
cluster members before the node is federated.  This is undesirable, because the
DMGR will collect those cluster members and their services and try to realize
them, which depends on federation.  If federation hasn’t been completed, this
will fail.

* DMGR has to run twice before App servers can federate, this is due to the
behavior of facts in Puppet.  The first time it runs, it will create a DMGR
profile.  Only after that profile is created can we obtain the SOAP port, which
is ultimately reported by Facter.  Facts only get evaluated at the beginning of
a run - that SOAP port was not available as a fact at the start of the first
run because a profile didn’t exist.  The second run will re-run facter at the
beginning, gathering and reporting the SOAP port so that it can be exported.

* If the DMGR does its SECOND run _after_ the app server has already ran once,
there will be non-fatal errors.  The DMGR will attempt to create a cluster
member from the app server’s node.  This fails because the node service isn’t
running on the app server yet.  The service can’t be started on the App server
yet because it hasn’t federated.  This is recoverable - the DMGR will keep
retrying until the app server’s node service is running and eventually be able
to complete this task assuming the App server has successfully started.  What
we need:  can we just not export the cluster_member stuff from the app server
until it’s federated?  We’d likely need a fact that determines if the node has
been federated.  This would add another Puppet run.

## FixPack installation and processes

IBM doesn't really have traditional package management.  They have their own
tool and ship their own package formats that have a `repository.config` file
included with various metadata.

When installing a FixPack, we have to look through the process table and kill
any processes that are running out of our target directory.  This is due to
Installation Manager - it doesn't take care of that for you and will refuse to
install if a service is running out of its target directory.

Since we kill the processes, they don't get restarted automatically.
Ultimately, this makes the puppet run that applies the fixpack to have failures
in it because resources depend on that service to be running.  They get
restarted on the next Puppet runs, however.

We should come up with a solution for that.

## Compatibility

This does not work with ruby 1.8. Not sure at this point what the scope of that
fix would be.

## Miscellany

The fact on the DMGR (at least) seems to be added and removed on every run:

```
Notice: /File[/var/opt/lib/pe-puppet/facts.d/websphere.yaml]/ensure: removed
Info: Retrieving plugin
Info: Loading facts
Info: Caching catalog for dmgr-centos
Info: Applying configuration version '1431535942'
Notice: /Stage[main]/Websphere/Concat[/var/opt/lib/pe-puppet/facts.d/websphere.yaml]/File[/var/opt/lib/pe-puppet/facts.d/websphere.yaml]/ensure: defined content as '{md5}ac194d927a3def8d9ecbd43fefed5d9a'
```

## Types and providers

Providers that don't use the namevar/probably need a rewriting
* websphere_jvm_log
* websphere_sdk
* websphere_variable
