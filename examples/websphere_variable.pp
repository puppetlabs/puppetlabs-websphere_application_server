websphere_variable { 'PROFILE_APP_001:CELL_01:LOG_ROOT_TEST':
  ensure       => 'present',
  variable     => 'LOG_ROOT_TEST',
  value        => '/opt/log/websphere/wasmgmtlogs/appNode01',
  scope        => 'node',
  node         => 'appNode01',
  cell         => 'CELL_01',
  dmgr_profile => 'PROFILE_APP_001',
  profile_base => '/opt/IBM/WebSphere85/Profiles',
  user         => 'webadmins',
}
