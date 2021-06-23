plan websphere_application_server::provision_machines(
  Optional[String] $using = 'abs',
  Optional[String] $image = 'centos-7-x86_64'
) {
  # provision machines, set roles
  ['server'].each |$role| {
    run_task("provision::${using}", 'localhost', action => 'provision', platform => $image, vars => "role: ${role}")
  }
}
