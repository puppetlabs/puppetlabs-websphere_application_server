plan websphere_application_server::agents_setup(
  Optional[String] $collection = 'puppet7',
) {
  # get pe_server ?
  $server = get_targets('*').filter |$n| { $n.vars['role'] == 'server' }

  # get agents ?
  $agents = get_targets('*').filter |$n| { $n.vars['role'] != 'server' }

  # install agents
  run_task('puppet_agent::install', $agents, { 'collection' => $collection })

  # set the server
  $server_string = $server[0].name
  run_task('puppet_conf', $agents, action => 'set', section => 'main', setting => 'server', value => $server_string)
  run_task('puppet_conf', $agents, action => 'set', section => 'main', setting => 'environment', value => 'production')
  run_task('puppet_conf', $agents, action => 'set', section => 'main', setting => 'runinterval', value => '1h')
  $agents.each |$agent| {
    run_task('puppet_conf', $agent, action => 'set', section => 'main', setting => 'certname', value => $agent.name)
    # agent sign request
    catch_errors() || {
      run_command('puppet agent -t', $agent, '_catch_errors' => true)
    }
  }

  # sign all certificates
  catch_errors() || {
    run_command('puppetserver ca sign --all', $server, '_catch_errors' => true)
  }
}
