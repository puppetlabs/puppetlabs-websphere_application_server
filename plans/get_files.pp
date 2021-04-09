plan websphere_application_server::get_files() {
  $all_agents = get_targets('*').filter |$node| { $node.vars['role'] != 'server' }

  run_command('mkdir -p /tmp/mountqa/ibm_websphere', $all_agents)
  ['FP', 'ndtrial', 'ibm_was_java', 'oracle', 'ihs_ilan', 'plg_ilan'].each |$package| {
    run_command("gsutil cp -r gs://artifactory-modules/${package}.tar.gz /tmp/", $all_agents)
    run_command("tar -xvf /tmp/${package}.tar.gz -C /tmp/mountqa/ibm_websphere", $all_agents)
    run_command("rm -f /tmp/${package}.tar.gz", $all_agents)
  }
  run_command('gsutil cp -r gs://artifactory-modules/agent.installer.linux.gtk.x86_64_1.8.7000.20170706_2137.zip /tmp/mountqa/ibm_websphere', $all_agents)
  run_command('chmod -R 755 /tmp/mountqa', $all_agents)
  run_command('chown -R root:root /tmp/mountqa', $all_agents)

  $data = run_command('ls /tmp/mountqa/ibm_websphere', $all_agents).to_data
  $data.each |$result_set| {
    out::message($result_set['target'])
    out::message("${result_set['value']['stdout']}\n")
  }
}
