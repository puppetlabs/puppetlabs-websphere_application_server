### Defined Type: `websphere::cluster::member`

This defined type is used for managing WebSphere cluster members in a cell.

This defined type is intended to be _exported_ by an application server and
_collected_ on a DMGR.

Essentially, this is just a wrapper for our native Ruby types, but it makes
it a little easier and abstracted for the end user.

This wraps the `websphere_cluster_member` and
`websphere_cluster_member_service` types.

#### Example

```puppet
# Export a cluster member
@@websphere::cluster::member { 'AppServer01':
  ensure                           => 'present',
  cluster                          => 'PuppetCluster01',
  node                             => 'appNode01',
  cell                             => 'CELL_01',
  jvm_maximum_heap_size            => '512',
  jvm_verbose_mode_class           => true,
  jvm_verbose_garbage_collection   => false,
  jvm_executable_jar_filename      => '',
  total_transaction_timeout        => '120',
  client_inactivity_timeout        => '20',
  threadpool_webcontainer_max_size => '75',
  runas_user                       => 'webadmin',
  runas_group                      => 'webadmins',
  dmgr_host                        => 'dmgr01.example.com',
}
```

#### Parameters

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
