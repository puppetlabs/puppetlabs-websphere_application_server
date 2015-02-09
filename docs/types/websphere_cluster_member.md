### Type: `websphere_cluster_member`

Manages members of a WebSphere server cluster.

#### Example

```puppet
websphere_cluster_member { 'AppServer01':
  ensure                => 'present',
  dmgr_profile          => 'PROFILE_DMGR_001',
  profile_base          => '/opt/IBM/WebSphere/AppServer/profiles',
  cell                  => 'CELL_01',
  cluster               => 'MyCluster01',
  user                  => 'webadmins',
  runas_user            => 'webadmins',
  runas_group           => 'webadmins',
  jvm_initial_heap_size => '1024',
}
```

#### Parameters

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
