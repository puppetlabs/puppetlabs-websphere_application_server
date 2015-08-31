websphere_variable { 'CELL_01:node:appNode01':
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
