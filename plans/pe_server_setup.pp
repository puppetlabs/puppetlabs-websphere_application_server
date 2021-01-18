plan websphere_application_server::pe_server_setup(
) {
  $pe_server =  get_targets('*').filter |$n| { $n.vars['role'] == 'server' }
  # install pe server
  run_task('provision::install_pe', $pe_server)

  # install the module
  run_command('puppet module install puppetlabs-websphere_application_server', $pe_server)

  # set the ui password
  run_command('puppet infra console_password --password=litmus', $pe_server)

  # work around for pe's module structure, for the UI
  run_command('ln -s /etc/puppetlabs/code/environments/production/modules/puppetlabs-websphere_application_server /opt/puppetlabs/puppet/modules', $pe_server)
  run_command('ln -s /etc/puppetlabs/code/environments/production/modules/ruby_task_helper /opt/puppetlabs/puppet/modules', $pe_server)
}
