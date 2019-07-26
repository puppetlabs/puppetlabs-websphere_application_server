# @summary
#   Defined type to manage cluster members and their service. 
#
# @example Manage a single cluster member
#   websphere_application_server::cluster::member { 'AppServer01':
#     ensure       => 'present',
#     cluster      => 'MyCluster01',
#     node_name    => 'appNode01',
#     cell         => 'CELL_01',
#     profile_base => '/opt/IBM/WebSphere/AppServer/profiles',
#     dmgr_profile => 'PROFILE_DMGR_01',
#   }
#
# This is intended to be exported by an application server and collected by a DMGR.  However, you *could* just declare it on a DMGR.
#
# @param profile_base
#   Required. The full path to the profiles directory where the `dmgr_profile` can  be found. The IBM default is `/opt/IBM/WebSphere/AppServer/profiles`.
# @param cluster
#   Required. The name of the cluster that this member should be managed under.
# @param node_name
#   The node that this cluster member should be created on.
# @param cell
#   Required. Specifies the cell where the cluster is, under which this member should be managed.
# @param dmgr_profile
#   Required. The name of the DMGR profile to create this cluster member under.
# @param cluster_member_name
#   Specifies the name for this cluster member. Defaults to the resource title.
# @param ensure
#   Specifies whether this cluster member should exist or not.
# @param user
#   Optional. The user to run the `wsadmin` command as. Defaults to 'root'.
# @param runas_user
#   Optional. Manages the `runAsUser` for a cluster member.
# @param runas_group
#   Optional. Manages the `runAsGroup` for a cluster member.
# @param client_inactivity_timeout
#   Optional. Manages the clientInactivityTimeout for the TransactionService.
# @param gen_unique_ports
#   Optional. Boolean. Specifies the `genUniquePorts` value when adding a cluster member.
# @param jvm_maximum_heap_size
#   Optional. Manages the `maximumHeapSize` setting for the cluster member's JVM.
# @param jvm_verbose_mode_class
#   Optional. Boolean. Manages the `verboseModeClass` setting for the cluster member's JVM
# @param jvm_verbose_garbage_collection
#   Optional. Boolean. Manages the `verboseGarbageCollection` setting for the cluster member's JVM
# @param jvm_verbose_mode_jni
#   Optional. Boolean. Manages the `verboseModeJNI` setting for the cluster member's JVM
# @param jvm_initial_heap_size
#   Optional. Manages the `initialHeapSize` setting for the cluster member's JVM.
# @param jvm_run_hprof
#   Optional. Boolean. Manages the `runHProf` setting for the cluster member's JVM.
# @param jvm_hprof_arguments
#   Optional. Manages the `hprofArguments` setting for the cluster member's JVM.
# @param jvm_debug_mode
#   Optional. Manages the `debugMode` setting for the cluster member's JVM.
# @param jvm_debug_args
#   Optional. Manages the `debugArgs` setting for the cluster member's JVM.
# @param jvm_executable_jar_filename
#   Optional. Manages the `executableJARFilename` setting for the cluster member's JVM.
# @param jvm_generic_jvm_arguments
#   Optional. Manages the `genericJvmArguments` setting for the cluster member's JVM.
# @param jvm_disable_jit
#   Optional. Manages the `disableJIT` setting for the cluster member's JVM.
# @param replicator_entry
#   This parameter is inactive.
# @param total_transaction_timeout
#   Optional. Manages the `totalTranLifetimeTimeout` for the Application Server.
# @param threadpool_webcontainer_min_size
#   Optional. Manages the `minimumSize` setting for the WebContainer ThreadPool.
# @param threadpool_webcontainer_max_size
#   Optional. Manages the `maximumSize` setting for the WebContainer ThreadPool.
# @param umask
#   Optional. Manages the `ProcessExecution` umask for a cluster member.
# @param wsadmin_user
#   Optional. The username for `wsadmin` authentication if security is enabled.
# @param wsadmin_pass
#   Optional. The password for `wsadmin` authentication if security is enabled.
# @param weight
#   Optional. Manages the cluster member weight (`memberWeight`) when adding a cluster member.
# @param manage_service
#   Specifies whether the corresponding service for the cluster member should be managed here or not.  This uses the `websphere_cluster_member_service` type to do so.
# @param dmgr_host
#   The DMGR host to add this cluster member to.  This is required if you're exporting the cluster member for a DMGR to collect. Otherwise, it's optional.
#
define websphere_application_server::cluster::member (
  Stdlib::AbsolutePath $profile_base,
  String $cluster,
  String $node_name,
  String $cell,
  String $dmgr_profile,
  String $cluster_member_name                        = $title,
  Enum[present, absent] $ensure                      = 'present',
  String $user                                       = $::websphere_application_server::user,
  String $runas_user                                 = $::websphere_application_server::user,
  String $runas_group                                = $::websphere_application_server::group,
  Optional[String] $client_inactivity_timeout        = undef,
  Optional[Boolean] $gen_unique_ports                = undef,
  Optional[String] $jvm_maximum_heap_size            = undef,
  Optional[Boolean] $jvm_verbose_mode_class          = undef,
  Optional[Boolean] $jvm_verbose_garbage_collection  = undef,
  Optional[Boolean] $jvm_verbose_mode_jni            = undef,
  Optional[String] $jvm_initial_heap_size            = undef,
  Optional[Boolean] $jvm_run_hprof                   = undef,
  Optional[String] $jvm_hprof_arguments              = undef,
  Optional[Boolean] $jvm_debug_mode                  = undef,
  Optional[String] $jvm_debug_args                   = undef,
  Optional[String] $jvm_executable_jar_filename      = undef,
  Optional[String] $jvm_generic_jvm_arguments        = undef,
  Optional[String] $jvm_disable_jit                  = undef,
  Optional[String] $replicator_entry                 = undef,
  Optional[String] $total_transaction_timeout        = undef,
  Optional[String] $threadpool_webcontainer_min_size = undef,
  Optional[String] $threadpool_webcontainer_max_size = undef,
  Optional[String] $umask                            = undef,
  Optional[String] $wsadmin_user                     = undef,
  Optional[String] $wsadmin_pass                     = undef,
  Optional[String] $weight                           = undef,
  Boolean $manage_service                            = true,
  Optional[Stdlib::Fqdn] $dmgr_host                  = undef,
) {

  if !$dmgr_profile or !$cluster {
    fail('dmgr_profile and cluster is required')
  }

  websphere_cluster_member { $cluster_member_name:
    ensure                           => $ensure,
    user                             => $user,
    dmgr_profile                     => $dmgr_profile,
    profile                          => $cluster_member_name,
    profile_base                     => $profile_base,
    cluster                          => $cluster,
    node_name                        => $node_name,
    cell                             => $cell,
    runas_user                       => $runas_user,
    runas_group                      => $runas_group,
    client_inactivity_timeout        => $client_inactivity_timeout,
    gen_unique_ports                 => $gen_unique_ports,
    jvm_maximum_heap_size            => $jvm_maximum_heap_size,
    jvm_verbose_mode_class           => $jvm_verbose_mode_class,
    jvm_verbose_garbage_collection   => $jvm_verbose_garbage_collection,
    jvm_verbose_mode_jni             => $jvm_verbose_mode_jni,
    jvm_initial_heap_size            => $jvm_initial_heap_size,
    jvm_run_hprof                    => $jvm_run_hprof,
    jvm_hprof_arguments              => $jvm_hprof_arguments,
    jvm_debug_mode                   => $jvm_debug_mode,
    jvm_debug_args                   => $jvm_debug_args,
    jvm_executable_jar_filename      => $jvm_executable_jar_filename,
    jvm_generic_jvm_arguments        => $jvm_generic_jvm_arguments,
    jvm_disable_jit                  => $jvm_disable_jit,
    replicator_entry                 => $replicator_entry,
    total_transaction_timeout        => $total_transaction_timeout,
    threadpool_webcontainer_min_size => $threadpool_webcontainer_min_size,
    threadpool_webcontainer_max_size => $threadpool_webcontainer_max_size,
    umask                            => $umask,
    wsadmin_user                     => $wsadmin_user,
    wsadmin_pass                     => $wsadmin_pass,
    weight                           => $weight,
    dmgr_host                        => $dmgr_host,
  }

  if $manage_service {
    $_service_ensure = $ensure ? { present => 'running', default => 'stopped' }

    websphere_cluster_member_service { $cluster_member_name:
      ensure       => $_service_ensure,
      dmgr_profile => $dmgr_profile,
      profile      => $cluster_member_name,
      profile_base => $profile_base,
      cell         => $cell,
      node_name    => $node_name,
      wsadmin_user => $wsadmin_user,
      wsadmin_pass => $wsadmin_pass,
      dmgr_host    => $dmgr_host,
      subscribe    => Websphere_cluster_member[$cluster_member_name],
    }
  }
}
