plan websphere_application_server::provision_gcp(
  Optional[String] $gcp_image = 'centos-7',
) {
  # provision server machine, set role 
  run_task('provision::provision_service', 'localhost', action => 'provision', platform => $gcp_image, vars => 'role: server')
  run_task('provision::provision_service', 'localhost', action => 'provision', platform => $gcp_image, vars => 'role: appserver')
  run_task('provision::provision_service', 'localhost', action => 'provision', platform => $gcp_image, vars => 'role: dmgr')
  run_task('provision::provision_service', 'localhost', action => 'provision', platform => $gcp_image, vars => 'role: ihs')
}
