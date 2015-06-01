# Defined type to manage cluster members and their service.
# This is really just a helper type to wrap up the
# 'websphere_cluster_member' and 'websphere_cluster_member_service' types.
# You're welcome to use those types directly.  This is just for less repitition
# to the end user.
#
# This is intended to be exported by an application server and collected by
# a DMGR.  However, you *could* just declare it on a DMGR.
#
define websphere_application_server::cluster::member (
  $profile_base,
  $cluster,
  $node,
  $cell,
  $dmgr_profile,
  $cluster_member_name              = $title,
  $ensure                           = 'present',
  $user                             = $::websphere_application_server::user,
  $runas_user                       = $::websphere_application_server::user,
  $runas_group                      = $::websphere_application_server::group,
  $client_inactivity_timeout        = undef,
  $gen_unique_ports                 = undef,
  $jvm_maximum_heap_size            = undef,
  $jvm_verbose_mode_class           = undef,
  $jvm_verbose_garbage_collection   = undef,
  $jvm_verbose_mode_jni             = undef,
  $jvm_initial_heap_size            = undef,
  $jvm_run_hprof                    = undef,
  $jvm_hprof_arguments              = undef,
  $jvm_debug_mode                   = undef,
  $jvm_debug_args                   = undef,
  $jvm_executable_jar_filename      = undef,
  $jvm_generic_jvm_arguments        = undef,
  $jvm_disable_jit                  = undef,
  $replicator_entry                 = undef,
  $total_transaction_timeout        = undef,
  $threadpool_webcontainer_min_size = undef,
  $threadpool_webcontainer_max_size = undef,
  $umask                            = undef,
  $wsadmin_user                     = undef,
  $wsadmin_pass                     = undef,
  $weight                           = undef,
  $manage_service                   = true,
  $dmgr_host                        = undef,
) {

  if !$dmgr_profile or !$cluster {
    fail('dmgr_profile and cluster is required')
  }

  validate_string($dmgr_profile)
  validate_absolute_path($profile_base)
  validate_string($cluster)
  validate_string($node)
  validate_string($cell)
  validate_string($user)

  if $runas_user                       { validate_string($runas_user) }
  if $runas_group                      { validate_string($runas_group) }
  if $client_inactivity_timeout        { validate_string($client_inactivity_timeout) }
  if $gen_unique_ports                 { validate_bool($gen_unique_ports) }
  if $jvm_maximum_heap_size            { validate_string($jvm_maximum_heap_size) }
  if $jvm_verbose_mode_class           { validate_bool($jvm_verbose_mode_class) }
  if $jvm_verbose_garbage_collection   { validate_bool($jvm_verbose_garbage_collection) }
  if $jvm_verbose_mode_jni             { validate_bool($jvm_verbose_mode_jni) }
  if $jvm_initial_heap_size            { validate_string($jvm_initial_heap_size) }
  if $jvm_run_hprof                    { validate_bool($jvm_run_hprof) }
  if $jvm_hprof_arguments              { validate_string($jvm_hprof_arguments) }
  if $jvm_debug_mode                   { validate_bool($jvm_debug_mode) }
  if $jvm_debug_args                   { validate_string($jvm_debug_args) }
  if $jvm_executable_jar_filename      { validate_string($jvm_executable_jar_filename) }
  if $jvm_generic_jvm_arguments        { validate_string($jvm_generic_jvm_arguments) }
  if $jvm_disable_jit                  { validate_string($jvm_disable_jit) }
  if $replicator_entry                 { validate_string($replicator_entry) }
  if $total_transaction_timeout        { validate_string($total_transaction_timeout) }
  if $threadpool_webcontainer_min_size { validate_string($threadpool_webcontainer_min_size) }
  if $threadpool_webcontainer_max_size { validate_string($threadpool_webcontainer_max_size) }
  if $umask                            { validate_string($umask) }
  if $wsadmin_user                     { validate_string($wsadmin_user) }
  if $wsadmin_pass                     { validate_string($wsadmin_pass) }
  if $weight                           { validate_string($weight) }

  websphere_cluster_member { $cluster_member_name:
    ensure                           => $ensure,
    user                             => $user,
    dmgr_profile                     => $dmgr_profile,
    profile_base                     => $profile_base,
    cluster                          => $cluster,
    node                             => $node,
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
    if $ensure == 'present' {
      $_service_ensure = 'running'
    } else {
      $_service_ensure = 'stopped'
    }

    websphere_cluster_member_service { $cluster_member_name:
      ensure       => $_service_ensure,
      dmgr_profile => $dmgr_profile,
      profile_base => $profile_base,
      cell         => $cell,
      node         => $node,
      wsadmin_user => $wsadmin_user,
      wsadmin_pass => $wsadmin_pass,
      dmgr_host    => $dmgr_host,
      subscribe    => Websphere_cluster_member[$cluster_member_name],
    }
  }

}
