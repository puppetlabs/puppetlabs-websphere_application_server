# dmgr
class websphere_role::dmgr { # lint:ignore:autoloader_layout
  include websphere_profile::nfs_mount
  include websphere_profile::base
  include websphere_profile::dmgr

  Class['websphere_profile::nfs_mount'] -> Class['websphere_profile::base'] -> Class['websphere_profile::dmgr']
}

# appserver
class websphere_role::appserver { # lint:ignore:autoloader_layout
  include websphere_profile::nfs_mount
  include websphere_profile::base
  include websphere_profile::appserver

  Class['websphere_profile::nfs_mount'] -> Class['websphere_profile::base'] -> Class['websphere_profile::appserver']
}
