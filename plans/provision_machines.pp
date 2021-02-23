plan websphere_application_server::provision_machines(
  Optional[String] $pe_server = 'centos-7-x86_64',
  Optional[String] $app_agent = 'centos-7-x86_64',
  Optional[String] $dmgr_agent = 'centos-7-x86_64',
  Optional[String] $ihs_agent = 'centos-7-x86_64',
) {
  # provision server machine, set role 
  run_task('provision::abs', 'localhost', action => 'provision', platform => $pe_server, vars => 'role: server')
  run_task('provision::abs', 'localhost', action => 'provision', platform => $app_agent, vars => 'role: appserver')
  run_task('provision::abs', 'localhost', action => 'provision', platform => $dmgr_agent, vars => 'role: dmgr')
  run_task('provision::abs', 'localhost', action => 'provision', platform => $ihs_agent, vars => 'role: ihs')
}
