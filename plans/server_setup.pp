plan websphere_application_server::server_setup() {
  # get server
  $server = get_targets('*').filter |$node| { $node.vars['role'] == 'server' }

  # install puppetserver and start on master
  run_task(
    'provision::install_puppetserver',
    $server,
    'install and configure server'
  )

  $server_string = $server[0].name
  run_task('puppet_conf', $server, action => 'set', section => 'master', setting => 'dns_alt_names', value => "\"${server_string}\",puppetserver")
  run_task('puppet_conf', $server, action => 'set', section => 'main', setting => 'server', value => $server_string)
  run_task('puppet_conf', $server, action => 'set', section => 'main', setting => 'certname', value => $server_string)
  run_task('puppet_conf', $server, action => 'set', section => 'main', setting => 'environment', value => 'production')
  run_task('puppet_conf', $server, action => 'set', section => 'main', setting => 'runinterval', value => '1h')
  run_task('puppet_conf', $server, action => 'set', section => 'main', setting => 'autosign', value => 'true')

  catch_errors() || {
    run_command('systemctl start puppetserver', $server, '_catch_errors' => true)
    run_command('systemctl enable puppetserver', $server, '_catch_errors' => true)
  }
}
