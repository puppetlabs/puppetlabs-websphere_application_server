plan websphere_application_server::acceptance::pe_server_setup(
) {
  $pe_server =  get_targets('*').filter |$n| { $n.vars['role'] == 'server' }
  # install pe server
  run_task('provision::install_pe', $pe_server)

  # set the ui password
  run_command('puppet infra console_password --password=litmus', $pe_server)
}
