plan websphere_application_server::provision_machines(
  Optional[String] $pe_master = 'centos-7-x86_64',
  Optional[String] $app_agent = 'centos-7-x86_64',
  Optional[String] $dmgr_agent = 'centos-7-x86_64',
  Optional[String] $ihs_agent = 'centos-7-x86_64',
) {
  # provision server machine, set role 
  run_task('provision::vmpooler', 'localhost', action => 'provision', platform => $pe_master, inventory => './', vars => 'role: master')
  run_task('provision::vmpooler', 'localhost', action => 'provision', platform => $app_agent, inventory => './', vars => 'role: appserver')
  run_task('provision::vmpooler', 'localhost', action => 'provision', platform => $dmgr_agent, inventory => './', vars => 'role: dmgr')
  run_task('provision::vmpooler', 'localhost', action => 'provision', platform => $ihs_agent, inventory => './', vars => 'role: ihs')
}